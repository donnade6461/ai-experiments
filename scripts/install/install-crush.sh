#!/bin/bash
set -euo pipefail

# Crush (OpenCode successor) Installation Script

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🔨 Installing Crush (OpenCode successor)...${NC}"

# Check if Go is installed for alternative installation
if command -v go &> /dev/null; then
    echo -e "${BLUE}📦 Installing via Go...${NC}"
    go install github.com/charmbracelet/crush@latest
    
    # Check if GOBIN is in PATH
    GOBIN=$(go env GOBIN)
    GOPATH=$(go env GOPATH)
    
    if [ -z "$GOBIN" ]; then
        GOBIN="$GOPATH/bin"
    fi
    
    if [[ ":$PATH:" != *":$GOBIN:"* ]]; then
        echo -e "${YELLOW}⚠️  Adding Go bin directory to PATH${NC}"
        echo 'export PATH="'$GOBIN':$PATH"' >> ~/.bashrc
        export PATH="$GOBIN:$PATH"
    fi
    
elif command -v brew &> /dev/null; then
    echo -e "${BLUE}🍺 Installing via Homebrew...${NC}"
    brew install charmbracelet/tap/crush
    
else
    echo -e "${BLUE}📥 Installing via direct download...${NC}"
    
    # Detect architecture
    ARCH=$(uname -m)
    case $ARCH in
        x86_64) ARCH="amd64" ;;
        aarch64|arm64) ARCH="arm64" ;;
        *) echo -e "${RED}❌ Unsupported architecture: $ARCH${NC}"; exit 1 ;;
    esac
    
    # Get latest release info
    echo "Fetching latest release information..."
    LATEST_URL="https://api.github.com/repos/charmbracelet/crush/releases/latest"
    
    # Try to get download URL
    DOWNLOAD_URL=$(curl -s "$LATEST_URL" | grep "browser_download_url.*linux_$ARCH" | cut -d '"' -f 4 | head -n1)
    
    if [ -z "$DOWNLOAD_URL" ]; then
        echo -e "${RED}❌ Could not find download URL for linux_$ARCH${NC}"
        echo "Available releases:"
        curl -s "$LATEST_URL" | grep "browser_download_url" | cut -d '"' -f 4
        exit 1
    fi
    
    echo "Downloading from: $DOWNLOAD_URL"
    
    # Download and install
    if wget -O /tmp/crush.tar.gz "$DOWNLOAD_URL"; then
        tar -xzf /tmp/crush.tar.gz -C /tmp
        sudo mv /tmp/crush /usr/local/bin/
        chmod +x /usr/local/bin/crush
        rm -f /tmp/crush.tar.gz
    else
        echo -e "${RED}❌ Failed to download Crush${NC}"
        exit 1
    fi
fi

# Verify installation
if command -v crush &> /dev/null; then
    echo -e "${GREEN}✅ Crush installed successfully!${NC}"
    echo "Version: $(crush --version)"
else
    echo -e "${RED}❌ Crush installation failed${NC}"
    exit 1
fi

# Setup configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
mkdir -p ~/.config/crush

if [ ! -f ~/.config/crush/crush.json ]; then
    cp "$PROJECT_ROOT/config/crush/crush.json" ~/.config/crush/
    echo -e "${GREEN}📋 Crush configuration copied to ~/.config/crush/${NC}"
else
    echo -e "${YELLOW}⚠️  Crush configuration already exists${NC}"
    echo "Backup existing and replace with new config? (y/N)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        cp ~/.config/crush/crush.json ~/.config/crush/crush.json.backup
        cp "$PROJECT_ROOT/config/crush/crush.json" ~/.config/crush/
        echo -e "${GREEN}📋 Configuration updated (backup saved)${NC}"
    fi
fi

# Create development-specific config
cat > ~/.config/crush/crush-dev.json << 'EOF'
{
  "$schema": "https://charm.land/crush.json",
  "providers": {
    "ollama-dev": {
      "name": "Local Development",
      "base_url": "http://localhost:11434/v1/",
      "type": "openai-compat",
      "models": [
        {
          "name": "Quick Coder",
          "id": "qwen2.5-coder:7b",
          "context_window": 32768,
          "default_max_tokens": 4096
        }
      ]
    }
  },
  "agents": {
    "dev": {
      "model": "qwen2.5-coder:7b",
      "maxTokens": 4000,
      "temperature": 0.1
    }
  },
  "options": {
    "debug": true,
    "auto_save": false
  }
}
EOF

echo -e "${GREEN}📋 Development configuration created${NC}"

# Test installation
echo -e "${BLUE}🧪 Testing Crush installation...${NC}"
if crush --help > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Crush is working correctly${NC}"
else
    echo -e "${YELLOW}⚠️  Crush test failed - may need to restart terminal${NC}"
fi

echo ""
echo -e "${GREEN}🎯 Crush setup complete!${NC}"
echo ""
echo -e "${BLUE}📍 Next steps:${NC}"
echo "   1. Restart your terminal or run: source ~/.bashrc"
echo "   2. Test with: crush --version"
echo "   3. Configure with: crush --config"
echo ""
echo -e "${BLUE}💡 Configuration files:${NC}"
echo "   • Main config: ~/.config/crush/crush.json"
echo "   • Dev config: ~/.config/crush/crush-dev.json"
echo ""
echo -e "${BLUE}🚀 Usage examples:${NC}"
echo '   • crush "Explain this code" --file main.py'
echo '   • crush "Generate a REST API in Go"'
echo '   • crush "Review this code for issues" --file src/handlers.go'