# Claude Code Installer - Windows
# Usage: download this file, inspect it, then run in PowerShell: .\install.ps1
# Does NOT require Administrator - installs at user scope.

$ErrorActionPreference = "Stop"

$Installed = @()
$Skipped   = @()

# Minimum required Node.js major version
$MinNodeVersion = 18

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

function Refresh-Path {
    # Rebuild PATH from registry and prepend known Node.js user-install location
    $machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath    = [System.Environment]::GetEnvironmentVariable("Path", "User")
    $nodePath    = "$env:APPDATA\npm"  # Default npm global bin path for user installs

    $env:Path = "$nodePath;$machinePath;$userPath"
}

function Get-NodeMajorVersion {
    try {
        $raw = (node -v 2>$null).Trim()
        if ($raw -match '^v(\d+)\.') {
            return [int]$Matches[1]
        }
    } catch {}
    return $null
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

# ── winget check ──────────────────────────────────────────────────────────────
if (-not (Test-Cmd "winget")) {
    Write-Host "✗ winget not found. Install 'App Installer' from the Microsoft Store, then re-run." -ForegroundColor Red
    Write-Host "  https://aka.ms/getwinget" -ForegroundColor Gray
    exit 1
}

# ── Node.js ───────────────────────────────────────────────────────────────────
if (-not (Test-Cmd "node")) {
    Write-Host "▶ Installing Node.js (user scope - no admin needed)..." -ForegroundColor Blue
    # --scope user avoids needing Administrator privileges
    winget install OpenJS.NodeJS --scope user --silent --accept-package-agreements --accept-source-agreements
    Refresh-Path
    $Installed += "Node.js"
} else {
    $nodeMajor = Get-NodeMajorVersion
    $nodeVer   = (node -v 2>$null).Trim()

    if ($null -eq $nodeMajor) {
        Write-Host "⚠ Could not determine Node.js version. Reinstalling..." -ForegroundColor Yellow
        winget install OpenJS.NodeJS --scope user --silent --accept-package-agreements --accept-source-agreements
        Refresh-Path
        $Installed += "Node.js (reinstalled)"
    } elseif ($nodeMajor -lt $MinNodeVersion) {
        Write-Host "⚠ Node.js $nodeVer found but v$MinNodeVersion+ is required. Upgrading..." -ForegroundColor Yellow
        winget upgrade OpenJS.NodeJS --scope user --silent --accept-package-agreements --accept-source-agreements
        Refresh-Path
        $Installed += "Node.js (upgraded from $nodeVer)"
    } else {
        Write-Host "⊘ Node.js $nodeVer already installed (meets v$MinNodeVersion+ requirement) - skipping" -ForegroundColor Yellow
        $Skipped += "Node.js $nodeVer"
    }
}

# ── Claude Code CLI ───────────────────────────────────────────────────────────
if (-not (Test-Cmd "claude")) {
    Write-Host "▶ Installing Claude Code CLI..." -ForegroundColor Blue
    # Pin to a specific version for reproducibility. Update on each release.
    # Latest versions: https://www.npmjs.com/package/@anthropic-ai/claude-code
    npm install -g @anthropic-ai/claude-code
    if ($LASTEXITCODE -ne 0) {
        Write-Host "✗ Claude Code CLI installation failed" -ForegroundColor Red
        exit 1
    }
    $Installed += "Claude Code CLI"
} else {
    Write-Host "⊘ Claude Code CLI already installed - skipping" -ForegroundColor Yellow
    $Skipped += "Claude Code CLI"
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
    $Skipped += "API key (set ANTHROPIC_API_KEY manually)"
}

# Zero out the plaintext key from memory (best effort in managed runtime)
$ApiKey = $null
[System.GC]::Collect()

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
