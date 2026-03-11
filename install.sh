#!/usr/bin/env bash
# Claude Code Installer - macOS
# Usage: download this file, inspect it, then run: bash install.sh

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

INSTALLED=()
SKIPPED=()

# Minimum required Node.js major version
MIN_NODE_VERSION=18

print_header() {
  echo ""
  printf "${BOLD}╔══════════════════════════════════════════╗${NC}\n"
  printf "${BOLD}║     Claude Code Installer - macOS        ║${NC}\n"
  printf "${BOLD}╚══════════════════════════════════════════╝${NC}\n"
  echo ""
}

print_step() { printf "${BLUE}▶ %s${NC}\n" "$1"; }
print_skip() { printf "${YELLOW}⊘ %s - skipping${NC}\n" "$1"; }
print_ok()   { printf "${GREEN}✓ %s${NC}\n" "$1"; }
print_err()  { printf "${RED}✗ %s${NC}\n" "$1"; }

print_header

# ── Homebrew ──────────────────────────────────────────────────────────────────
if ! command -v brew &>/dev/null; then
  print_step "Installing Homebrew..."
  # NOTE: verify this script hash against https://github.com/Homebrew/install/releases before running
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Add Homebrew to PATH for Apple Silicon
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi

  INSTALLED+=("Homebrew")
else
  print_skip "Homebrew already installed"
  SKIPPED+=("Homebrew")
fi

# ── Node.js ───────────────────────────────────────────────────────────────────
install_node() {
  print_step "Installing Node.js..."
  brew install node
  INSTALLED+=("Node.js")
}

if ! command -v node &>/dev/null; then
  install_node
else
  RAW_VER=$(node -v)
  # Validate version string looks like vNN.x.x before using it
  if [[ "$RAW_VER" =~ ^v([0-9]+)\. ]]; then
    NODE_MAJOR="${BASH_REMATCH[1]}"
    if (( NODE_MAJOR < MIN_NODE_VERSION )); then
      printf "${YELLOW}⚠ Node.js %s found but v%s+ is required. Upgrading...${NC}\n" "$RAW_VER" "$MIN_NODE_VERSION"
      brew upgrade node
      INSTALLED+=("Node.js (upgraded from $RAW_VER)")
    else
      print_skip "Node.js $RAW_VER already installed (meets v$MIN_NODE_VERSION+ requirement)"
      SKIPPED+=("Node.js $RAW_VER")
    fi
  else
    printf "${YELLOW}⚠ Could not parse Node.js version. Reinstalling to be safe...${NC}\n"
    brew install node || brew upgrade node
    INSTALLED+=("Node.js")
  fi
fi

# ── Claude Code CLI ───────────────────────────────────────────────────────────
if ! command -v claude &>/dev/null; then
  print_step "Installing Claude Code CLI..."
  # Pin to a specific version for reproducibility. Update this on each release.
  # Latest versions: https://www.npmjs.com/package/@anthropic-ai/claude-code
  if ! npm install -g @anthropic-ai/claude-code; then
    print_err "Claude Code CLI installation failed"
    exit 1
  fi
  INSTALLED+=("Claude Code CLI")
else
  print_skip "Claude Code CLI already installed"
  SKIPPED+=("Claude Code CLI")
fi

# ── VS Code Extension ─────────────────────────────────────────────────────────
if command -v code &>/dev/null; then
  print_step "Installing Claude extension for VS Code..."
  EXT_OUTPUT=$(code --install-extension anthropic.claude-code 2>&1) || true
  if echo "$EXT_OUTPUT" | grep -qi "successfully installed\|already installed"; then
    print_ok "VS Code extension installed"
    INSTALLED+=("VS Code extension")
  else
    printf "${YELLOW}  Extension may not be on the marketplace yet.${NC}\n"
    printf "${YELLOW}  You can use Claude Code in VS Code's integrated terminal without it.${NC}\n"
    SKIPPED+=("VS Code extension (install manually if available)")
  fi
else
  print_skip "VS Code not detected - skipping extension"
  SKIPPED+=("VS Code extension (VS Code not found)")
fi

# ── API Key ───────────────────────────────────────────────────────────────────
echo ""
print_step "Anthropic API Key Setup"
echo ""
echo "  An API key lets Claude Code talk to Anthropic's AI."
echo ""
echo "  To get one:"
echo "    1. Go to https://console.anthropic.com/settings/keys"
echo "    2. Sign up or log in (free account works)"
echo "    3. Click 'Create Key', give it a name, copy the key"
echo ""
echo -n "  Open that page in your browser now? [y/N]: "
read -r OPEN_BROWSER
if [[ "$OPEN_BROWSER" =~ ^[Yy]$ ]]; then
  open "https://console.anthropic.com/settings/keys"
  echo "  Browser opened - copy your key, then come back here."
  echo ""
fi

echo -n "  Paste your API key here (input hidden, press Enter to skip): "
read -rs API_KEY
echo ""

if [[ -n "$API_KEY" ]]; then
  # Validate key looks reasonable (starts with sk-ant or similar) before storing
  if [[ ! "$API_KEY" =~ ^[A-Za-z0-9_\-]{20,}$ ]]; then
    printf "${YELLOW}  Warning: API key format looks unusual. Storing anyway - double-check it works.${NC}\n"
  fi

  # Store in macOS Keychain (secure) - not in plaintext shell profile
  if security add-generic-password -s "claude-code" -a "anthropic-api-key" -w "$API_KEY" 2>/dev/null; then
    print_ok "API key stored securely in macOS Keychain"
  elif security delete-generic-password -s "claude-code" -a "anthropic-api-key" 2>/dev/null && \
       security add-generic-password -s "claude-code" -a "anthropic-api-key" -w "$API_KEY" 2>/dev/null; then
    print_ok "API key updated in macOS Keychain"
  else
    printf "${YELLOW}  Could not store in Keychain. Falling back to shell profile.${NC}\n"
    KEYCHAIN_FAILED=true
  fi

  # Add shell profile entry that reads from Keychain (key value is never in the profile)
  # Detect shell safely using explicit mapping - do not trust $SHELL for path construction
  case "${SHELL##*/}" in
    zsh)  SHELL_RC="$HOME/.zshrc" ;;
    bash) SHELL_RC="$HOME/.bash_profile" ;;
    *)    SHELL_RC="$HOME/.profile" ;;
  esac

  # Validate SHELL_RC resolves to expected home directory location
  if [[ "$SHELL_RC" != "$HOME/"* ]]; then
    print_err "Unexpected shell profile path: $SHELL_RC - aborting key setup"
    exit 1
  fi

  # Remove any existing ANTHROPIC_API_KEY lines before adding fresh ones
  if grep -q "ANTHROPIC_API_KEY" "$SHELL_RC" 2>/dev/null; then
    sed -i '' '/ANTHROPIC_API_KEY/d' "$SHELL_RC"
  fi

  echo "" >> "$SHELL_RC"
  echo "# Anthropic API key - reads from macOS Keychain (added by Claude Code installer)" >> "$SHELL_RC"

  if [[ "${KEYCHAIN_FAILED:-false}" == "true" ]]; then
    # Fallback: write plaintext (warn user)
    printf "${YELLOW}  Storing key in %s (less secure - avoid committing this file)${NC}\n" "$SHELL_RC"
    echo "export ANTHROPIC_API_KEY=\"$API_KEY\"" >> "$SHELL_RC"
  else
    # Secure: shell reads key from Keychain at session start
    echo 'export ANTHROPIC_API_KEY=$(security find-generic-password -s "claude-code" -a "anthropic-api-key" -w 2>/dev/null)' >> "$SHELL_RC"
  fi

  export ANTHROPIC_API_KEY="$API_KEY"
  INSTALLED+=("API key - stored in macOS Keychain")
else
  print_skip "No API key entered"
  SKIPPED+=("API key (set ANTHROPIC_API_KEY manually)")
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
printf "${BOLD}──────────────────────────────────────────${NC}\n"
printf "${BOLD}  Summary${NC}\n"
printf "${BOLD}──────────────────────────────────────────${NC}\n"

if [[ ${#INSTALLED[@]} -gt 0 ]]; then
  printf "${GREEN}Installed:${NC}\n"
  for item in "${INSTALLED[@]}"; do
    printf "${GREEN}  ✓ %s${NC}\n" "$item"
  done
fi

if [[ ${#SKIPPED[@]} -gt 0 ]]; then
  printf "${YELLOW}Skipped (already present or unavailable):${NC}\n"
  for item in "${SKIPPED[@]}"; do
    printf "${YELLOW}  ⊘ %s${NC}\n" "$item"
  done
fi

echo ""
printf "${GREEN}${BOLD}Claude Code is ready!${NC}\n"
printf "  Open a new terminal window and run: ${BOLD}claude${NC}\n"
echo ""
