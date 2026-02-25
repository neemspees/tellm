# tellm

A minimal macOS CLI tool that talks to Apple Intelligence on-device via the FoundationModels framework. No API keys, no network — just the local model on your Mac.

## Requirements

- macOS 26 (Tahoe) or later
- Apple Silicon (or Intel Mac with Apple Intelligence support)
- Xcode 26+

## Install

**Homebrew:**

```bash
brew tap neemspees/tellm https://github.com/neemspees/tellm
brew install tellm
```

**From source:**

```bash
swift build -c release
cp .build/release/tellm /usr/local/bin/tellm
```

## Usage

**Direct prompt:**

```bash
tellm "Explain the builder pattern in Swift"
```

**Pipe content with an instruction:**

```bash
git diff --cached | tellm -i "Generate a commit message based on these changes"
```

**Use in scripts:**

```bash
git commit -m "$(git diff --cached | tellm -q -i "Write a short commit message for these changes")"
```

**Pipe content without an instruction:**

```bash
cat error.log | tellm "What went wrong here?"
```

## Flags

| Flag | Short | Description |
|---|---|---|
| `--version` | | Print the current version |
| `--instruction` | `-i` | Provide a prompt separately from piped input |
| `--quiet` | `-q` | Suppress status messages (e.g. "Thinking...") |

## Behavior

- When input is piped, the output is trimmed to a single clean string and the model is instructed to return raw results only (no markdown, no code blocks).
- When used interactively (no pipe), the model responds freely.
- Status messages go to stderr, so they never pollute stdout or `$()` captures.
- Exits with code `1` on any error, `0` on success.
