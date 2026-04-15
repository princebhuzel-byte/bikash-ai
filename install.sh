#!/bin/bash
set -e # Exit on any error

# --- Colors for pretty output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Configuration ---
PACKAGE_NAME="bikash-ai"
GITHUB_REPO="your-username/bikash-ai" # CHANGE THIS!
INSTALL_DIR="$HOME/.local/bin"
BINARY_NAME="bikash"

# --- Helper Functions ---
print_error() { echo -e "${RED}❌ Error: $1${NC}" >&2; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

# --- Detect OS and Architecture ---
detect_platform() {
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)
    case $ARCH in
        x86_64) ARCH="x64" ;;
        aarch64|arm64) ARCH="arm64" ;;
        *) print_error "Unsupported architecture: $ARCH"; exit 1 ;;
    esac
    
    case $OS in
        linux) PLATFORM="linux" ;;
        darwin) PLATFORM="macos" ;;
        *) print_error "Unsupported OS: $OS"; exit 1 ;;
    esac
}

# --- Main Installation ---
main() {
    detect_platform
    
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  🚀 Installing Bikash-AI               ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo ""
    print_info "Detected platform: $PLATFORM-$ARCH"

    # 1. Create the installation directory if it doesn't exist
    mkdir -p "$INSTALL_DIR"

    # 2. Fetch the latest release info from GitHub
    print_info "Fetching latest release info from GitHub..."
    RELEASE_URL="https://api.github.com/repos/$GITHUB_REPO/releases/latest"
    RELEASE_INFO=$(curl -s "$RELEASE_URL")
    
    # Check for rate limiting
    if echo "$RELEASE_INFO" | grep -q "API rate limit exceeded"; then
        print_warning "GitHub API rate limit hit. Falling back to a known version."
        LATEST_VERSION="v1.0.0" # Fallback version
    else
        LATEST_VERSION=$(echo "$RELEASE_INFO" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        if [ -z "$LATEST_VERSION" ]; then
            print_error "Could not determine latest version."
            exit 1
        fi
    fi
    print_info "Latest version: $LATEST_VERSION"

    # 3. Build the download URL for the appropriate binary
    BINARY_NAME_FULL="${PACKAGE_NAME}-${PLATFORM}-${ARCH}.tar.gz"
    DOWNLOAD_URL="https://github.com/$GITHUB_REPO/releases/download/$LATEST_VERSION/$BINARY_NAME_FULL"
    print_info "Downloading $DOWNLOAD_URL ..."

    # 4. Download and extract
    TMP_DIR=$(mktemp -d)
    curl -L "$DOWNLOAD_URL" -o "$TMP_DIR/$BINARY_NAME_FULL"
    tar -xzf "$TMP_DIR/$BINARY_NAME_FULL" -C "$TMP_DIR"
    
    # 5. Move the binary to the install directory
    mv "$TMP_DIR/$BINARY_NAME" "$INSTALL_DIR/$BINARY_NAME"
    chmod +x "$INSTALL_DIR/$BINARY_NAME"
    rm -rf "$TMP_DIR"
    print_success "Installed to $INSTALL_DIR/$BINARY_NAME"

    # 6. Add to PATH if needed
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        print_info "Adding $INSTALL_DIR to your PATH..."
        SHELL_CONFIG=""
        case $SHELL in
            */zsh) SHELL_CONFIG="$HOME/.zshrc" ;;
            */bash) SHELL_CONFIG="$HOME/.bashrc" ;;
            */fish) SHELL_CONFIG="$HOME/.config/fish/config.fish" ;;
        esac
        
        if [ -n "$SHELL_CONFIG" ]; then
            echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$SHELL_CONFIG"
            print_success "Added to $SHELL_CONFIG. Please restart your terminal or run 'source $SHELL_CONFIG'."
        else
            print_warning "Could not detect your shell. Please add $INSTALL_DIR to your PATH manually."
        fi
    fi

    # 7. Verify the installation
    if command -v "$BINARY_NAME" >/dev/null 2>&1; then
        print_success "Installation complete! Run 'bikash --help' to get started."
    else
        print_warning "Installation might be complete, but 'bikash' is not in your PATH yet."
        print_info "You can run it directly with: $INSTALL_DIR/$BINARY_NAME"
    fi
}

main "$@"
