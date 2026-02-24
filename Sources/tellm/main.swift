import Foundation
import FoundationModels

private func parseArgs() -> (prompt: String, stdin: String?, quiet: Bool) {
    var args = Array(CommandLine.arguments.dropFirst())
    
    let quiet = removeFlag(&args, long: "--quiet", short: "-q")
    let prompt = removeValueFlag(&args, long: "--instruction", short: "-i")
        ?? args.joined(separator: " ")
    
    var stdinContent: String? = nil
    if isatty(fileno(stdin)) == 0 {
        stdinContent = readLine(strippingNewline: false).map { first in
            var lines = [first]
            while let line = readLine(strippingNewline: false) {
                lines.append(line)
            }
            return lines.joined()
        }
    }
    
    return (prompt, stdinContent, quiet)
}

private func removeFlag(_ args: inout [String], long: String, short: String) -> Bool {
    guard let index = args.firstIndex(of: long) ?? args.firstIndex(of: short) else { return false }
    args.remove(at: index)
    return true
}

private func removeValueFlag(_ args: inout [String], long: String, short: String) -> String? {
    guard let index = args.firstIndex(of: long) ?? args.firstIndex(of: short),
          index + 1 < args.count else { return nil }
    let value = args[index + 1]
    args.removeSubrange(index...index + 1)
    return value
}

private func buildPrompt(_ prompt: String, stdin: String?) -> String {
    guard let stdin, !stdin.isEmpty else { return prompt }
    guard !prompt.isEmpty else { return stdin }
    return "\(prompt)\n\n---\n\(stdin)"
}

private func makeSession(hasPipedInput: Bool) -> LanguageModelSession {
    guard hasPipedInput else { return LanguageModelSession() }
    return LanguageModelSession(instructions: "Respond with ONLY the raw result. No markdown, no code blocks, no explanations.")
}

@MainActor
func runPrompt() async {
    let model = SystemLanguageModel.default
    let status = model.availability
    
    switch status {
    case .available:
        let (prompt, stdinContent, quiet) = parseArgs()
        let fullPrompt = buildPrompt(prompt, stdin: stdinContent)
        
        guard !fullPrompt.isEmpty else {
            print("Usage: tellm \"your prompt\"", to: &standardError)
            print("       echo \"content\" | tellm -i \"your instruction\"", to: &standardError)
            exit(1)
        }
        
        let session = makeSession(hasPipedInput: stdinContent != nil)
        
        do {
            if !quiet { print("🤖 Thinking...", to: &standardError) }
            let response = try await session.respond(to: fullPrompt)
            let output = stdinContent != nil
                ? response.content.trimmingCharacters(in: .whitespacesAndNewlines)
                : response.content
            print(output)
        } catch {
            print("❌ Generation Error: \(error)", to: &standardError)
            exit(1)
        }
        
    case .unavailable(let reason):
        print("❌ Model Unavailable", to: &standardError)
        print("Reason: \(String(describing: reason))", to: &standardError)
        exit(1)
        
    @unknown default:
        print("❓ Unknown availability status.", to: &standardError)
        exit(1)
    }
}

private struct StandardError: TextOutputStream {
    mutating func write(_ string: String) {
        FileHandle.standardError.write(Data(string.utf8))
    }
}
private var standardError = StandardError()

let task = Task {
    await runPrompt()
    exit(0)
}

dispatchMain()
