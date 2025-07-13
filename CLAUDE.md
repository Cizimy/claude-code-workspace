# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Workspace Overview

This is a Claude Code-enabled development workspace implementing Test-Driven Development (TDD) with automated quality guards. The workspace is designed to manage multiple projects with consistent development practices.

**System Configuration**:
- 🎯 **Development Method**: Test-Driven Development (TDD) with automated guards
- 📏 **Design Principle**: YAGNI (You Aren't Gonna Need It)
- 🔄 **Workflow**: GitHub Issue-driven development
- 🛡️ **Quality Control**: Automated hooks for TDD compliance, unused code detection, and coverage checking

## Core Principles

### 1. Test-Driven Development (TDD)
- **Red → Green → Refactor**: Write failing tests first, then minimal implementation, then improve
- **No implementation without tests**: The TDD Guard hook blocks implementation changes without prior test changes
- **Test coverage minimum**: 60% (enforced by coverage-check.sh)

### 2. YAGNI Principle
- **Implement only what's needed now**: No speculative features
- **Unused code forbidden**: Automatic detection and removal via unused-detector.sh
- **Keep it simple**: Choose the simplest solution that works

### 3. Quality Guards (Hooks)
- **Pre-Tool Hook**: `tdd-guard.sh` - Blocks implementation changes without test changes
- **Post-Tool Hook**: `unused-detector.sh` - Detects unused functions/variables after edits
- **Stop Hook**: `coverage-check.sh` - Ensures quality standards before completion

## Development Commands

### Custom Claude Code Commands
```bash
# Start new feature development with TDD workflow
/project:new-feature [issue_number]

# Fix bugs with test-first approach
/project:fix-bug [issue_number]
```

### Project-Specific Commands

#### Python Projects (danbooru_advanced_wildcard)
```bash
# Run tests
pytest
pytest tests/test_specific.py  # Run specific test

# Run tests with coverage
pytest --cov=src --cov-report=term-missing

# Check for unused code
vulture .

# Lint code
ruff check

# Format code
ruff format
```

#### VBA Projects (pdi)
- VBA projects have relaxed TDD requirements due to language limitations
- Manual testing approach with structured validation
- Focus on module integrity and function documentation

### Common Development Tasks
```bash
# Git operations (allowed)
git status
git diff
git log
git commit -m "message"
gh pr create

# File operations
ls -la
find . -name "*.py"
grep -r "pattern" .
rg "pattern"  # ripgrep for faster searches

# Python development
pip install -r requirements.txt
python -m venv venv
source venv/bin/activate  # Linux/Mac
venv\Scripts\activate     # Windows
```

## Workspace Structure

```
C:\Users\kenic\Projects\
├── .claude/                    # Claude Code configuration
│   ├── commands/              # Custom command definitions
│   ├── hooks/                 # Quality guard scripts
│   │   ├── pre-tool/         # TDD enforcement
│   │   ├── post-tool/        # Unused code detection
│   │   └── stop/             # Coverage checking
│   ├── docs/                  # Development documentation
│   └── settings.json          # Tool permissions and hook config
├── governance/                # Project governance
│   ├── adr/                  # Architecture Decision Records
│   ├── decision_log.md       # Decision tracking
│   └── mtg_minutes/          # Meeting minutes
└── projects/                  # Individual projects directory
```

## Tool Permissions

### Allowed Operations
- File reading/writing/editing (Read, Write, Edit, MultiEdit)
- Directory navigation (LS, Glob, Grep)
- Git operations (git status, diff, commit, log)
- Package management (npm, pip, python)
- Testing tools (pytest, make)
- GitHub CLI (gh)
- Web fetch for specific domains (github.com, docs.anthropic.com, zenn.dev)

### Denied Operations
- Destructive file operations (rm, rmdir, mv, cp)
- Permission changes (chmod, chown)
- Privileged operations (sudo, su)
- General web access (except allowed domains)

## Development Workflow

1. **Issue Creation**: Start with a GitHub issue describing the feature/bug
2. **Command Invocation**: Use `/project:new-feature` or `/project:fix-bug`
3. **TDD Cycle**:
   - Write failing tests first
   - Implement minimal code to pass tests
   - Refactor while keeping tests green
4. **Quality Checks**: Automated hooks ensure:
   - Tests exist before implementation
   - No unused code remains
   - Coverage meets minimum threshold
5. **PR Creation**: Use `gh pr create` with comprehensive description

## Hook Behavior

### TDD Guard (pre-tool)
- **Triggers on**: Edit, MultiEdit operations
- **Blocks when**: Attempting to edit implementation files without recent test changes
- **Exemptions**: Test files, config files, documentation, VBA files

### Unused Code Detector (post-tool)
- **Triggers on**: After file edits
- **Detects**: Unused functions, variables, imports
- **Tools used**: vulture (Python), ESLint (JavaScript)
- **Action**: Reports unused code that must be removed

### Coverage Check (stop)
- **Triggers on**: Before Claude Code session ends
- **Checks**: Test coverage >= 60%
- **Project-specific**: Different thresholds per project

## Error Handling

### Common Hook Issues
```bash
# Fix hook permissions on Unix-like systems
chmod +x .claude/hooks/*/*.sh

# View hook logs
tail -f /tmp/claude-hooks.log

# Check for CRLF issues on Windows
sed -i 's/\r$//' .claude/hooks/*/*.sh
```

### Bypass Guards (Emergency Only)
```bash
# Temporarily disable hooks (use sparingly)
export CLAUDE_HOOKS_DISABLED=true
```

## Project-Specific Notes

### danbooru_advanced_wildcard (Python)
- Strict TDD enforcement
- Minimum 80% test coverage
- Use pytest for testing
- Use ruff for linting and formatting

### pdi (VBA)
- Relaxed TDD requirements due to VBA limitations
- Focus on module structure validation
- Manual testing documentation required

## Related Documentation

- **Governance**: `/governance/README.md` - Decision tracking and ADRs
- **Commands**: `/.claude/commands/README.md` - Custom command details
- **Hooks**: `/.claude/hooks/README.md` - Hook implementation details
- **Templates**: `/.claude/docs/02_templates/` - Reusable templates

---

*This CLAUDE.md serves as the constitution for AI-driven development in this workspace. All development must follow these principles and use the configured quality guards.*

*Last updated: 2025-01-13*