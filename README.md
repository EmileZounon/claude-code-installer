# Claude Code Installer

Automated installer for [Claude Code](https://claude.ai/code) - sets up everything needed to start using Claude Code from your terminal and VS Code in one step.

## What it installs

| Component | macOS | Windows |
|---|---|---|
| Homebrew / winget | (if missing) | pre-required |
| Node.js | yes | yes |
| Claude Code CLI | yes | yes |
| VS Code extension | yes (if VS Code found) | yes (if VS Code found) |
| Anthropic API key | stored in macOS Keychain | stored in protected file |

Already installed? The script detects existing components and skips them - you'll see a summary at the end of what was installed vs skipped.

---

## Step 1 - Open your terminal

### On macOS

1. Press **Command (cmd) + Space** to open Spotlight Search
2. Type **Terminal** and press **Enter**
3. A black or white window will open - that's your terminal

### On Windows

1. Click the **Start menu** (Windows icon, bottom-left of your screen)
2. Type **PowerShell**
3. Click **Windows PowerShell** to open it
4. A blue window will open - that's PowerShell

> No need to run as Administrator. The installer works at user level.

---

## Step 2 - Download the installer

Download the file for your OS and save it somewhere easy to find (like your Desktop):

- **macOS:** [Download install.sh](https://github.com/EmileZounon/claude-code-installer/releases/download/v1.0.0/install.sh)
- **Windows:** [Download install.ps1](https://github.com/EmileZounon/claude-code-installer/releases/download/v1.0.0/install.ps1)

> **Why download instead of copy-paste?** Downloading lets you open the file and read what it does before running it. Always a good habit with installers.

---

## Step 3 - Run the installer

### macOS

In your terminal, type the following and press **Enter** (replace `~/Desktop` if you saved it elsewhere):

```bash
bash ~/Desktop/install.sh
```

### Windows

In PowerShell, type the following and press **Enter** (replace the path if you saved it elsewhere):

```powershell
.\install.ps1
```

If you see a message about the script not being allowed to run, paste this first and press **Enter**, then try again:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

The installer will guide you through the rest - just follow the prompts on screen.

---

## What happens during install

1. **Checks for prerequisites** - Node.js, npm, VS Code
2. **Installs missing tools** - Homebrew (macOS) or winget (Windows) used as package manager
3. **Checks Node.js version** - upgrades automatically if below minimum (v18)
4. **Installs Claude Code CLI** via npm
5. **Installs the Claude VS Code extension** if VS Code is detected
6. **Prompts for your Anthropic API key** - stored securely in macOS Keychain (macOS) or a restricted file (Windows). Never written in plaintext to your shell profile.
7. **Prints a summary** of everything installed or skipped

---

## After install

Open a **new terminal window** and run:

```bash
claude
```

You're in. Start talking to Claude Code.

### Using with VS Code

Open VS Code's integrated terminal (Ctrl + backtick or Cmd + backtick) and run `claude` from there. Claude Code integrates with VS Code automatically - it can open files directly in your editor as you work.

---

## Get your API key

Visit [console.anthropic.com/settings/keys](https://console.anthropic.com/settings/keys) to create or retrieve your key.

The installer will offer to open this page for you and walk you through the setup.

If you skipped the key setup during install, set it manually:

**macOS** - store in Keychain then add to your shell profile:
```bash
security add-generic-password -s "claude-code" -a "anthropic-api-key" -w "your-key-here"
echo 'export ANTHROPIC_API_KEY=$(security find-generic-password -s "claude-code" -a "anthropic-api-key" -w 2>/dev/null)' >> ~/.zshrc
```

**Windows** - save to a protected file:
```powershell
New-Item -ItemType Directory -Force "$HOME\.anthropic" | Out-Null
Set-Content "$HOME\.anthropic\credentials" "your-key-here" -NoNewline
```
Then add this to your PowerShell profile (`$PROFILE`):
```powershell
$env:ANTHROPIC_API_KEY = (Get-Content "$HOME\.anthropic\credentials" -Raw).Trim()
```

---

## Requirements

| | macOS | Windows |
|---|---|---|
| OS version | macOS 12+ | Windows 10/11 |
| Shell | zsh or bash | PowerShell 5.1+ |
| Package manager | Homebrew (auto-installed) | winget (built into Windows 10/11) |

---

## Contributors

- [Emile Zounon](https://github.com/EmileZounon)
- [Claude](https://claude.ai) (Anthropic)

---

## Build Log

| | |
|---|---|
| Start | 2026-03-10 |
| End | 2026-03-10 |
| Model | Claude Sonnet 4.6 |
