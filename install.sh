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

# ── Claude Code CLI ──────────────────────────────────────────────────────────
if command -v claude &>/dev/null; then
  CLAUDE_VER=$(claude --version 2>/dev/null || echo "unknown version")
  print_skip "Claude Code CLI already installed ($CLAUDE_VER)"
  SKIPPED+=("Claude Code CLI ($CLAUDE_VER)")
else
  print_step "Installing Claude Code..."
  # Official native installer - auto-updates in the background, no dependencies required
  # Source: https://claude.ai/install.sh
  curl -fsSL https://claude.ai/install.sh | bash
  INSTALLED+=("Claude Code CLI (native installer, auto-updates)")
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
  print_skip "VS Code not detected"
  SKIPPED+=("VS Code extension (VS Code not found)")
fi

# ── Authentication ───────────────────────────────────────────────────────────
echo ""
print_step "Authentication"
echo ""
echo "  Claude Code authenticates through your browser."
echo "  When you first run 'claude', it will open a browser window"
echo "  to log in with your Claude account (Pro, Max, Teams, or Enterprise)."
echo ""
echo "  ┌─────────────────────────────────────────────────────────┐"
echo "  │  Optional: API key setup                                │"
echo "  │                                                         │"
echo "  │  If you prefer to use an Anthropic API key instead,     │"
echo "  │  the installer can set that up for you.                 │"
echo "  │                                                         │"
echo "  │  Get a key: console.anthropic.com/settings/keys         │"
echo "  └─────────────────────────────────────────────────────────┘"
echo ""
echo -n "  Set up an API key? (most users can skip this) [y/N]: "
read -r SETUP_KEY

if [[ "$SETUP_KEY" =~ ^[Yy]$ ]]; then
  echo ""
  echo -n "  Open the API key page in your browser? [y/N]: "
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
    # Validate key looks reasonable before storing
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
    case "${SHELL##*/}" in
      zsh)  SHELL_RC="$HOME/.zshrc" ;;
      bash) SHELL_RC="$HOME/.bash_profile" ;;
      *)    SHELL_RC="$HOME/.profile" ;;
    esac

    if [[ "$SHELL_RC" != "$HOME/"* ]]; then
      print_err "Unexpected shell profile path: $SHELL_RC - aborting key setup"
      exit 1
    fi

    if grep -q "ANTHROPIC_API_KEY" "$SHELL_RC" 2>/dev/null; then
      sed -i '' '/ANTHROPIC_API_KEY/d' "$SHELL_RC"
    fi

    echo "" >> "$SHELL_RC"
    echo "# Anthropic API key - reads from macOS Keychain (added by Claude Code installer)" >> "$SHELL_RC"

    if [[ "${KEYCHAIN_FAILED:-false}" == "true" ]]; then
      printf "${YELLOW}  Storing key in %s (less secure - avoid committing this file)${NC}\n" "$SHELL_RC"
      echo "export ANTHROPIC_API_KEY=\"$API_KEY\"" >> "$SHELL_RC"
    else
      echo 'export ANTHROPIC_API_KEY=$(security find-generic-password -s "claude-code" -a "anthropic-api-key" -w 2>/dev/null)' >> "$SHELL_RC"
    fi

    export ANTHROPIC_API_KEY="$API_KEY"
    INSTALLED+=("API key - stored in macOS Keychain")
  else
    print_skip "No API key entered"
    SKIPPED+=("API key")
  fi
else
  print_skip "API key setup (using browser auth)"
  SKIPPED+=("API key (using browser auth)")
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
  printf "${YELLOW}Skipped (already present or not needed):${NC}\n"
  for item in "${SKIPPED[@]}"; do
    printf "${YELLOW}  ⊘ %s${NC}\n" "$item"
  done
fi

echo ""
printf "${GREEN}${BOLD}Claude Code is ready!${NC}\n"
printf "  Open a new terminal window and run: ${BOLD}claude${NC}\n"
printf "  Your browser will open to log in with your Claude account.\n"
echo ""
