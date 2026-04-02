# Claude Code Installer - Windows
# Usage: download this file, inspect it, then run in PowerShell: .\install.ps1
# Does NOT require Administrator - installs at user scope.

$ErrorActionPreference = "Stop"

$Installed = @()
$Skipped   = @()

function Write-Header {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║     Claude Code Installer - Windows      ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Test-Cmd($cmd) {
    return [bool](Get-Command $cmd -ErrorAction SilentlyContinue)
}

function Save-ApiKeySecurely($ApiKey) {
    # Store in a restricted-permission credentials file (not plaintext env var or registry)
    $credDir  = "$HOME\.anthropic"
    $credFile = "$credDir\credentials"

    New-Item -ItemType Directory -Force -Path $credDir | Out-Null

    # Write key to file
    Set-Content -Path $credFile -Value $ApiKey -NoNewline -Encoding UTF8

    # Restrict NTFS permissions: remove inheritance, grant only current user Read
    try {
        $acl = Get-Acl $credFile
        $acl.SetAccessRuleProtection($true, $false)  # Break inheritance
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $env:USERNAME, "Read,Write", "Allow"
        )
        $acl.SetAccessRule($rule)
        Set-Acl $credFile $acl
    } catch {
        Write-Host "  Note: Could not restrict file permissions. Ensure $credFile is kept private." -ForegroundColor Yellow
    }

    return $credFile
}

function Add-ToProfile($credFile) {
    # Add a line to PowerShell profile that reads the key from the credentials file at session start
    $profilePath = $PROFILE.CurrentUserAllHosts
    if (-not (Test-Path (Split-Path $profilePath))) {
        New-Item -ItemType Directory -Force -Path (Split-Path $profilePath) | Out-Null
    }
    if (-not (Test-Path $profilePath)) {
        New-Item -ItemType File -Force -Path $profilePath | Out-Null
    }

    # Remove existing entry to avoid duplicates
    $content = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue
    if ($content -match "ANTHROPIC_API_KEY") {
        $content = $content -replace '(?m)^.*ANTHROPIC_API_KEY.*\r?\n?', ''
        Set-Content $profilePath $content
    }

    Add-Content $profilePath "`n# Anthropic API key - reads from credentials file (added by Claude Code installer)"
    Add-Content $profilePath "if (Test-Path '$credFile') { `$env:ANTHROPIC_API_KEY = (Get-Content '$credFile' -Raw).Trim() }"
}

Write-Header

# ── Prerequisites ────────────────────────────────────────────────────────────
# Git for Windows is required by Claude Code on Windows
if (-not (Test-Cmd "git")) {
    Write-Host "⚠ Git for Windows not found. Claude Code requires it on Windows." -ForegroundColor Yellow
    Write-Host "  Install from: https://git-scm.com/downloads/win" -ForegroundColor Gray
    Write-Host ""
}

# ── Claude Code CLI ──────────────────────────────────────────────────────────
if (Test-Cmd "claude") {
    $ver = claude --version 2>$null
    Write-Host "⊘ Claude Code CLI already installed ($ver) - skipping" -ForegroundColor Yellow
    $Skipped += "Claude Code CLI ($ver)"
} else {
    if (Test-Cmd "winget") {
        # winget is the cleanest install path on Windows
        Write-Host "▶ Installing Claude Code via winget..." -ForegroundColor Blue
        winget install Anthropic.ClaudeCode --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -ne 0) {
            Write-Host "✗ Claude Code installation via winget failed" -ForegroundColor Red
            exit 1
        }
        $Installed += "Claude Code CLI (via winget)"
    } else {
        # Fallback to native installer if winget is not available
        Write-Host "▶ Installing Claude Code via native installer..." -ForegroundColor Blue
        Invoke-Expression (Invoke-RestMethod https://claude.ai/install.ps1)
        $Installed += "Claude Code CLI (native installer)"
    }
}

# ── VS Code Extension ─────────────────────────────────────────────────────────
if (Test-Cmd "code") {
    Write-Host "▶ Installing Claude extension for VS Code..." -ForegroundColor Blue
    $extOutput = code --install-extension anthropic.claude-code 2>&1
    if ($extOutput -match "successfully installed|already installed") {
        Write-Host "✓ VS Code extension installed" -ForegroundColor Green
        $Installed += "VS Code extension"
    } else {
        Write-Host "  Extension may not be on the marketplace yet." -ForegroundColor Yellow
        Write-Host "  You can use Claude Code in VS Code's integrated terminal without it." -ForegroundColor Yellow
        $Skipped += "VS Code extension (install manually if available)"
    }
} else {
    Write-Host "⊘ VS Code not detected - skipping extension" -ForegroundColor Yellow
    $Skipped += "VS Code extension (VS Code not found)"
}

# ── Authentication ───────────────────────────────────────────────────────────
Write-Host ""
Write-Host "▶ Authentication" -ForegroundColor Blue
Write-Host ""
Write-Host "  Claude Code authenticates through your browser."
Write-Host "  When you first run 'claude', it will open a browser window"
Write-Host "  to log in with your Claude account (Pro, Max, Teams, or Enterprise)."
Write-Host ""
Write-Host "  ┌─────────────────────────────────────────────────────────┐"
Write-Host "  │  Optional: API key setup                                │"
Write-Host "  │                                                         │"
Write-Host "  │  If you prefer to use an Anthropic API key instead,     │"
Write-Host "  │  the installer can set that up for you.                 │"
Write-Host "  │                                                         │"
Write-Host "  │  Get a key: console.anthropic.com/settings/keys         │"
Write-Host "  └─────────────────────────────────────────────────────────┘"
Write-Host ""
$SetupKey = Read-Host "  Set up an API key? (most users can skip this) [y/N]"

if ($SetupKey -match "^[Yy]$") {
    Write-Host ""
    $OpenBrowser = Read-Host "  Open the API key page in your browser? [y/N]"
    if ($OpenBrowser -match "^[Yy]$") {
        Start-Process "https://console.anthropic.com/settings/keys"
        Write-Host "  Browser opened - copy your key, then come back here."
        Write-Host ""
    }

    $SecureKey = Read-Host "  Paste your API key here (press Enter to skip)" -AsSecureString

    # Convert SecureString to string for storage, then zero out the BSTR immediately
    $bstr   = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureKey)
    $ApiKey = [Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)  # Zero and free BSTR from memory

    if ($ApiKey -and $ApiKey.Length -gt 0) {
        # Validate key looks reasonable before storing
        if ($ApiKey -notmatch '^[A-Za-z0-9_\-]{20,}$') {
            Write-Host "  Warning: API key format looks unusual. Storing anyway - double-check it works." -ForegroundColor Yellow
        }

        # Store in a restricted-permission file - not in plaintext env var or registry
        $credFile = Save-ApiKeySecurely $ApiKey
        Add-ToProfile $credFile

        # Set for current session
        $env:ANTHROPIC_API_KEY = $ApiKey

        Write-Host "✓ API key stored securely in $credFile (restricted permissions)" -ForegroundColor Green
        Write-Host "  Your PowerShell profile will load it automatically on future sessions." -ForegroundColor Gray
        $Installed += "API key - stored in $credFile"
    } else {
        Write-Host "⊘ No API key entered - skipping" -ForegroundColor Yellow
        $Skipped += "API key"
    }

    # Zero out the plaintext key from memory (best effort in managed runtime)
    $ApiKey = $null
    [System.GC]::Collect()
} else {
    Write-Host "⊘ API key setup skipped (using browser auth instead)" -ForegroundColor Yellow
    $Skipped += "API key (using browser auth)"
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
    Write-Host "Skipped (already present or not needed):" -ForegroundColor Yellow
    foreach ($item in $Skipped) {
        Write-Host "  ⊘ $item" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Claude Code is ready!" -ForegroundColor Green
Write-Host "  Open a new terminal window and run: claude"
Write-Host "  Your browser will open to log in with your Claude account."
Write-Host ""
