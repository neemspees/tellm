import ArgumentParser
import Foundation
import FoundationModels

@main
struct Tellm: AsyncParsableCommand {
    @Flag(name: [.long, .short], help: "Suppress status messages.")
    var quiet = false

    @Flag(name: [.long, .short], help: "Show extra progress info.")
    var verbose = false

    @Option(name: [.long, .short], help: "Instruction to apply to piped input.")
    var instruction: String?

    @Argument(help: "The prompt to send to the model.")
    var words: [String] = []

    mutating func run() async throws {
        let model = SystemLanguageModel.default
        let status = model.availability

        switch status {
        case .available:
            let prompt = instruction ?? words.joined(separator: " ")
            let stdinContent = readStdin()

            guard !prompt.isEmpty || (stdinContent != nil && !stdinContent!.isEmpty) else {
                print("Usage: tellm \"your prompt\"", to: &standardError)
                print("       echo \"content\" | tellm -i \"your instruction\"", to: &standardError)
                throw ExitCode.failure
            }

            do {
                if !quiet { print("🤖 Thinking...", to: &standardError) }
                let output = try await respond(to: prompt, content: stdinContent, quiet: quiet, verbose: verbose)
                print(output)
            } catch {
                print("❌ Generation Error: \(error)", to: &standardError)
                throw ExitCode.failure
            }

        case .unavailable(let reason):
            print("❌ Model Unavailable", to: &standardError)
            print("Reason: \(String(describing: reason))", to: &standardError)
            throw ExitCode.failure

        @unknown default:
            print("❓ Unknown availability status.", to: &standardError)
            throw ExitCode.failure
        }
    }
}

// MARK: - Stdin

private func readStdin() -> String? {
    guard isatty(fileno(stdin)) == 0 else { return nil }
    return readLine(strippingNewline: false).map { first in
        var lines = [first]
        while let line = readLine(strippingNewline: false) {
            lines.append(line)
        }
        return lines.joined()
    }
}

// MARK: - Chunking

private let chunkContentChars = 8_000

private func splitOnLines(_ text: String, maxChars: Int) -> [String] {
    guard text.count > maxChars else { return [text] }
    var chunks: [String] = []
    var remaining = text[...]
    while !remaining.isEmpty {
        let end = remaining.index(remaining.startIndex, offsetBy: maxChars, limitedBy: remaining.endIndex) ?? remaining.endIndex
        let splitPoint = remaining[..<end].lastIndex(of: "\n") ?? end
        chunks.append(String(remaining[..<splitPoint]))
        remaining = remaining[splitPoint...].drop(while: { $0 == "\n" })
    }
    return chunks
}

// MARK: - Response generation

private let plainOutputInstructions = """
    Respond with a SINGLE short plain-text result. \
    No markdown, no code blocks, no explanations, no lists, no per-section breakdown. \
    One unified answer only.
    """

private let chunkInstructions = "Summarize in 1-2 sentences. Plain English only, no code."

@MainActor
private func respond(to prompt: String, content: String?, quiet: Bool, verbose: Bool) async throws -> String {
    guard let content, !content.isEmpty else {
        let session = LanguageModelSession()
        let response = try await session.respond(to: prompt)
        return response.content
    }

    let chunks = splitOnLines(content, maxChars: chunkContentChars)
    if verbose {
        print("📄 Processing \(chunks.count) parts...", to: &standardError)
    }

    var summaries: [String] = []
    for chunk in chunks {
        let chunkSession = LanguageModelSession(instructions: chunkInstructions)
        let response = try await chunkSession.respond(to: "Please summarize the following content in English:\n\n\(chunk)")
        summaries.append(response.content.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    let combined = summaries.joined(separator: " ")
    let finalPrompt = prompt.isEmpty ? combined : "\(prompt)\n\n---\n\(combined)"
    let session = LanguageModelSession(instructions: plainOutputInstructions)
    let response = try await session.respond(to: finalPrompt)
    return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
}

// MARK: - Stderr

private struct StandardError: TextOutputStream {
    mutating func write(_ string: String) {
        FileHandle.standardError.write(Data(string.utf8))
    }
}
nonisolated(unsafe) private var standardError = StandardError()
