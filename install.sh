#!/usr/bin/env bash
# Claude Code Installer - macOS
# Usage: curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/claude-code-installer/main/install.sh | bash

set -e

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
  echo -e "${BOLD}╔══════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}║     Claude Code Installer - macOS        ║${NC}"
  echo -e "${BOLD}╚══════════════════════════════════════════╝${NC}"
  echo ""
}

print_step() { echo -e "${BLUE}▶ $1${NC}"; }
print_skip() { echo -e "${YELLOW}⊘ $1 - skipping${NC}"; }
print_ok()   { echo -e "${GREEN}✓ $1${NC}"; }
print_err()  { echo -e "${RED}✗ $1${NC}"; }

print_header

# ── Homebrew ──────────────────────────────────────────────────────────────────
if ! command -v brew &>/dev/null; then
  print_step "Installing Homebrew..."
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
if ! command -v node &>/dev/null; then
  print_step "Installing Node.js..."
  brew install node
  INSTALLED+=("Node.js")
else
  NODE_VER=$(node -v)
  print_skip "Node.js $NODE_VER already installed"
  SKIPPED+=("Node.js $NODE_VER")
fi

# ── Claude Code CLI ───────────────────────────────────────────────────────────
if ! command -v claude &>/dev/null; then
  print_step "Installing Claude Code CLI..."
  npm install -g @anthropic-ai/claude-code
  INSTALLED+=("Claude Code CLI")
else
  print_skip "Claude Code CLI already installed"
  SKIPPED+=("Claude Code CLI")
fi

# ── VS Code Extension ─────────────────────────────────────────────────────────
if command -v code &>/dev/null; then
  print_step "Installing Claude extension for VS Code..."
  if code --install-extension anthropic.claude-code 2>/dev/null; then
    INSTALLED+=("VS Code extension")
  else
    echo -e "${YELLOW}  Extension not found in marketplace - you can use Claude Code in VS Code's integrated terminal without it.${NC}"
    SKIPPED+=("VS Code extension (install manually if needed)")
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
  # Detect shell profile
  if [[ "$SHELL" == *"zsh"* ]]; then
    SHELL_RC="$HOME/.zshrc"
  elif [[ "$SHELL" == *"bash"* ]]; then
    SHELL_RC="$HOME/.bash_profile"
  else
    SHELL_RC="$HOME/.profile"
  fi

  # Remove existing key entry to avoid duplicates
  if grep -q "ANTHROPIC_API_KEY" "$SHELL_RC" 2>/dev/null; then
    sed -i '' '/ANTHROPIC_API_KEY/d' "$SHELL_RC"
  fi

  echo "" >> "$SHELL_RC"
  echo "# Anthropic API key (added by Claude Code installer)" >> "$SHELL_RC"
  echo "export ANTHROPIC_API_KEY=\"$API_KEY\"" >> "$SHELL_RC"
  export ANTHROPIC_API_KEY="$API_KEY"

  print_ok "API key saved to $SHELL_RC"
  INSTALLED+=("API key → $SHELL_RC")
else
  print_skip "No API key entered"
  SKIPPED+=("API key (set ANTHROPIC_API_KEY manually)")
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}──────────────────────────────────────────${NC}"
echo -e "${BOLD}  Summary${NC}"
echo -e "${BOLD}──────────────────────────────────────────${NC}"

if [[ ${#INSTALLED[@]} -gt 0 ]]; then
  echo -e "${GREEN}Installed:${NC}"
  for item in "${INSTALLED[@]}"; do
    echo -e "  ${GREEN}✓ $item${NC}"
  done
fi

if [[ ${#SKIPPED[@]} -gt 0 ]]; then
  echo -e "${YELLOW}Skipped (already present or unavailable):${NC}"
  for item in "${SKIPPED[@]}"; do
    echo -e "  ${YELLOW}⊘ $item${NC}"
  done
fi

echo ""
echo -e "${GREEN}${BOLD}Claude Code is ready!${NC}"
echo -e "  Open a new terminal window and run: ${BOLD}claude${NC}"
echo ""
