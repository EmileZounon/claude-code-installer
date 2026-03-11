# Claude Code Installer

Automated installer for [Claude Code](https://claude.ai/code) — sets up everything needed to start using Claude Code from your terminal and VS Code in one step.

## What it installs

| Component | macOS | Windows |
|---|---|---|
| Homebrew / winget | ✓ (if missing) | pre-required |
| Node.js | ✓ | ✓ |
| Claude Code CLI | ✓ | ✓ |
| VS Code extension | ✓ (if VS Code found) | ✓ (if VS Code found) |
| Anthropic API key | ✓ (saved to shell profile) | ✓ (saved to env variables) |

Already installed? The script detects existing components and skips them — you'll see a summary at the end of what was installed vs skipped.

---

## Option 1 — One-liner (paste in terminal)

### macOS

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/claude-code-installer/main/install.sh | bash
```

### Windows (PowerShell)

```powershell
iwr -useb https://raw.githubusercontent.com/YOUR_USERNAME/claude-code-installer/main/install.ps1 | iex
```

> **Windows note:** Run PowerShell as Administrator for best results. If you see an execution policy error, run this first:
> ```powershell
> Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
> ```

---

## Option 2 — Download and run manually

1. Download the file for your OS:
   - macOS: [`install.sh`](install.sh)
   - Windows: [`install.ps1`](install.ps1)

2. Run it:

   **macOS**
   ```bash
   chmod +x install.sh
   ./install.sh
   ```

   **Windows** (in PowerShell)
   ```powershell
   .\install.ps1
   ```

---

## What happens during install

1. **Checks for prerequisites** — Node.js, npm, VS Code
2. **Installs missing tools** — Homebrew (macOS) or winget (Windows) used as package manager
3. **Installs Claude Code CLI** via npm
4. **Installs the Claude VS Code extension** if VS Code is detected
5. **Prompts for your Anthropic API key** — stored securely in your shell profile (macOS) or user environment variables (Windows). You can press Enter to skip and set it later.
6. **Prints a summary** of everything installed or skipped

---

## After install

Open a **new terminal window** (required to pick up PATH changes) and run:

```bash
claude
```

You're in. Start talking to Claude Code.

### Using with VS Code

Open VS Code's integrated terminal (`Ctrl+`` ` or `Cmd+`` `) and run `claude` from there. Claude Code integrates with VS Code automatically — it can open files directly in your editor as you work.

---

## Get your API key

Visit [console.anthropic.com/settings/keys](https://console.anthropic.com/settings/keys) to create or retrieve your key.

If you skipped the key setup during install, add it manually:

**macOS** — add to `~/.zshrc` or `~/.bash_profile`:
```bash
export ANTHROPIC_API_KEY="your-key-here"
```

**Windows** — set as a user environment variable:
```powershell
[System.Environment]::SetEnvironmentVariable("ANTHROPIC_API_KEY", "your-key-here", "User")
```

---

## Requirements

| | macOS | Windows |
|---|---|---|
| OS version | macOS 12+ | Windows 10/11 |
| Shell | zsh or bash | PowerShell 5.1+ |
| Package manager | Homebrew (auto-installed) | winget (built into Windows 10/11) |

---

## Build Log

| | |
|---|---|
| Start | 2026-03-10 |
| End | 2026-03-10 |
| Model | Claude Sonnet 4.6 |
