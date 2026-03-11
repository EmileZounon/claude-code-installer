# Claude Code Installer — Windows
# Usage: iwr -useb https://raw.githubusercontent.com/YOUR_USERNAME/claude-code-installer/main/install.ps1 | iex
# Requires: PowerShell 5.1+ and winget (pre-installed on Windows 10/11)

$ErrorActionPreference = "Stop"

$Installed = @()
$Skipped   = @()

function Write-Header {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║     Claude Code Installer — Windows      ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Test-Cmd($cmd) {
    return [bool](Get-Command $cmd -ErrorAction SilentlyContinue)
}

function Refresh-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("Path", "User")
}

Write-Header

# ── winget check ──────────────────────────────────────────────────────────────
if (-not (Test-Cmd "winget")) {
    Write-Host "✗ winget not found. Install 'App Installer' from the Microsoft Store, then re-run." -ForegroundColor Red
    Write-Host "  https://aka.ms/getwinget" -ForegroundColor Gray
    exit 1
}

# ── Node.js ───────────────────────────────────────────────────────────────────
if (-not (Test-Cmd "node")) {
    Write-Host "▶ Installing Node.js..." -ForegroundColor Blue
    winget install OpenJS.NodeJS --silent --accept-package-agreements --accept-source-agreements
    Refresh-Path
    $Installed += "Node.js"
} else {
    $nodeVer = node -v
    Write-Host "⊘ Node.js $nodeVer already installed — skipping" -ForegroundColor Yellow
    $Skipped += "Node.js $nodeVer"
}

# ── Claude Code CLI ───────────────────────────────────────────────────────────
if (-not (Test-Cmd "claude")) {
    Write-Host "▶ Installing Claude Code CLI..." -ForegroundColor Blue
    npm install -g @anthropic-ai/claude-code
    $Installed += "Claude Code CLI"
} else {
    Write-Host "⊘ Claude Code CLI already installed — skipping" -ForegroundColor Yellow
    $Skipped += "Claude Code CLI"
}

# ── VS Code Extension ─────────────────────────────────────────────────────────
if (Test-Cmd "code") {
    Write-Host "▶ Installing Claude extension for VS Code..." -ForegroundColor Blue
    try {
        $result = code --install-extension anthropic.claude-code 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ VS Code extension installed" -ForegroundColor Green
            $Installed += "VS Code extension"
        } else {
            Write-Host "  Extension not found in marketplace — you can use Claude Code in VS Code's integrated terminal without it." -ForegroundColor Yellow
            $Skipped += "VS Code extension (install manually if needed)"
        }
    } catch {
        Write-Host "  Could not install VS Code extension automatically." -ForegroundColor Yellow
        $Skipped += "VS Code extension (install manually if needed)"
    }
} else {
    Write-Host "⊘ VS Code not detected — skipping extension" -ForegroundColor Yellow
    $Skipped += "VS Code extension (VS Code not found)"
}

# ── API Key ───────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "▶ Anthropic API Key Setup" -ForegroundColor Blue
Write-Host ""
Write-Host "  An API key lets Claude Code talk to Anthropic's AI."
Write-Host ""
Write-Host "  To get one:"
Write-Host "    1. Go to https://console.anthropic.com/settings/keys"
Write-Host "    2. Sign up or log in (free account works)"
Write-Host "    3. Click 'Create Key', give it a name, copy the key"
Write-Host ""
$OpenBrowser = Read-Host "  Open that page in your browser now? [y/N]"
if ($OpenBrowser -match "^[Yy]$") {
    Start-Process "https://console.anthropic.com/settings/keys"
    Write-Host "  Browser opened — copy your key, then come back here."
    Write-Host ""
}

$SecureKey = Read-Host "  Paste your API key here (press Enter to skip)" -AsSecureString
$ApiKey = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureKey)
)

if ($ApiKey -and $ApiKey.Length -gt 0) {
    [System.Environment]::SetEnvironmentVariable("ANTHROPIC_API_KEY", $ApiKey, "User")
    $env:ANTHROPIC_API_KEY = $ApiKey
    Write-Host "✓ API key saved to user environment variables" -ForegroundColor Green
    $Installed += "API key → User environment variables"
} else {
    Write-Host "⊘ No API key entered — skipping" -ForegroundColor Yellow
    $Skipped += "API key (set ANTHROPIC_API_KEY manually)"
}

# ── Summary ───────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "──────────────────────────────────────────" -ForegroundColor Gray
Write-Host "  Summary" -ForegroundColor White
Write-Host "──────────────────────────────────────────" -ForegroundColor Gray

if ($Installed.Count -gt 0) {
    Write-Host "Installed:" -ForegroundColor Green
    foreach ($item in $Installed) {
        Write-Host "  ✓ $item" -ForegroundColor Green
    }
}

if ($Skipped.Count -gt 0) {
    Write-Host "Skipped (already present or unavailable):" -ForegroundColor Yellow
    foreach ($item in $Skipped) {
        Write-Host "  ⊘ $item" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Claude Code is ready!" -ForegroundColor Green
Write-Host "  Open a new terminal window and run: claude"
Write-Host ""
