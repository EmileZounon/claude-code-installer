# Claude Code Installer

Automated installer for [Claude Code](https://claude.ai/code) - sets up Claude Code CLI, VS Code extension, and optional API key in one step.

## What it installs

| Component | macOS | Windows |
|---|---|---|
| Claude Code CLI | native installer (auto-updates) | winget (or native installer) |
| VS Code extension | yes (if VS Code found) | yes (if VS Code found) |
| Anthropic API key | stored in macOS Keychain (optional) | stored in protected file (optional) |

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

- **macOS:** [Download install.sh](https://github.com/EmileZounon/claude-code-installer/releases/download/v2.0.0/install.sh)
- **Windows:** [Download install.ps1](https://github.com/EmileZounon/claude-code-installer/releases/download/v2.0.0/install.ps1)

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

1. **Installs Claude Code CLI** using the official native installer (macOS) or winget (Windows) - no Node.js or npm required
2. **Installs the Claude VS Code extension** if VS Code is detected
3. **Offers optional API key setup** - most users authenticate via browser instead (see below)
4. **Prints a summary** of everything installed or skipped

---

## After install

Open a **new terminal window** and run:

```bash
claude
```

Your browser will open to log in with your Claude account (Pro, Max, Teams, or Enterprise). That's it.

Claude Code auto-updates in the background - no maintenance required.

### Using with VS Code

Open VS Code's integrated terminal (Ctrl + backtick or Cmd + backtick) and run `claude` from there. Claude Code integrates with VS Code automatically - it can open files directly in your editor as you work.

---

## API key setup (optional)

Most users authenticate through their browser when they first run `claude`. An API key is only needed if you're using Claude Code with direct API access.

The installer offers to set this up for you. If you skipped it during install, set it manually:

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

Visit [console.anthropic.com/settings/keys](https://console.anthropic.com/settings/keys) to create or retrieve your key.

---

## Requirements

| | macOS | Windows |
|---|---|---|
| OS version | macOS 13+ | Windows 10 1809+ |
| Shell | zsh or bash | PowerShell 5.1+ |
| Other | | [Git for Windows](https://git-scm.com/downloads/win) |

---

## Contributors

- [Emile Zounon](https://github.com/EmileZounon)
- [Claude](https://claude.ai) (Anthropic)

---

## Build Log

| | |
|---|---|
| v1.0 | 2026-03-10 (npm-based install) |
| v2.0 | 2026-04-02 (native installer, browser auth) |
| Model | Claude Sonnet 4.6, Claude Opus 4.6 |
