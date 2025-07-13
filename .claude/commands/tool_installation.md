# Tool Installation Guide

## Current Status
- ✅ **ripgrep**: Already installed via Claude Code
- ❌ **GitHub CLI**: Not installed
- ❌ **jq**: Not installed

## Installation Instructions

### GitHub CLI
```bash
# For Ubuntu/Debian
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh

# Or using package manager
sudo apt install gh
```

### jq
```bash
# For Ubuntu/Debian
sudo apt install jq

# Or using package manager
sudo apt-get install jq
```

## Verification
```bash
# After installation, verify tools
command -v gh && echo "GitHub CLI installed" || echo "GitHub CLI not found"
command -v jq && echo "jq installed" || echo "jq not found"
command -v rg && echo "ripgrep installed" || echo "ripgrep not found"
```

## Tool Benefits for Workspace

### GitHub CLI (gh)
- Repository management from command line
- Pull request creation and management
- Issue tracking and management
- Authentication and API access

### jq
- JSON processing and filtering
- Configuration file manipulation
- API response parsing
- Data transformation

### ripgrep (rg)
- Fast file content search
- Cross-project code search
- Pattern matching and filtering
- Performance optimization for large codebases

## Alternative Solutions
If installation is restricted:
- Use built-in tools like `grep` instead of `rg`
- Use `curl` and `cat` instead of `jq` for simple JSON operations
- Use GitHub web interface instead of CLI