#!/bin/bash

# セキュリティ検証Hook - Phase 5 IMP-006 実装
# 目的: 基本的なセキュリティ問題の検出（Secret scanning, 依存関係脆弱性）

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
LOG_FILE="/tmp/claude-hooks.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [security-check.sh] $1" | tee -a "$LOG_FILE"
}

log "Security check hook activated: tool=${CLAUDE_TOOL_NAME:-unknown}"

# 非セキュリティ関連ツールはスキップ
if [[ "${CLAUDE_TOOL_NAME:-unknown}" != "Edit" && "${CLAUDE_TOOL_NAME:-unknown}" != "MultiEdit" && "${CLAUDE_TOOL_NAME:-unknown}" != "Write" ]]; then
    log "Non-security-relevant tool, skipping security check: ${CLAUDE_TOOL_NAME:-unknown}"
    exit 0
fi

# 現在のワーキングディレクトリを取得
CURRENT_DIR="$(pwd)"
log "Current working directory: $CURRENT_DIR"

# 基本的なSecret scanning（簡易版）
check_secrets() {
    local file_path="$1"
    
    if [[ ! -f "$file_path" ]]; then
        return 0
    fi
    
    # 基本的なSecret patterns
    local secret_patterns=(
        "password\s*=\s*[\"'][^\"']{6,}[\"']"
        "api_key\s*=\s*[\"'][^\"']{16,}[\"']"
        "secret\s*=\s*[\"'][^\"']{16,}[\"']"
        "token\s*=\s*[\"'][^\"']{16,}[\"']"
        "-----BEGIN [A-Z ]+-----"
    )
    
    for pattern in "${secret_patterns[@]}"; do
        if grep -iE "$pattern" "$file_path" > /dev/null 2>&1; then
            log "⚠️  Potential secret detected in $file_path"
            log "Pattern: $pattern"
            return 1
        fi
    done
    
    return 0
}

# 依存関係の基本チェック
check_dependencies() {
    local project_dir="$1"
    
    # requirements.txtの基本チェック
    if [[ -f "$project_dir/requirements.txt" ]]; then
        # 既知の脆弱性のある古いバージョンの簡易チェック
        local vulnerable_packages=(
            "django<3.0"
            "flask<1.0"
            "requests<2.20"
            "pillow<6.2.0"
        )
        
        for pkg in "${vulnerable_packages[@]}"; do
            if grep -E "^${pkg%%<*}.*${pkg##*<}" "$project_dir/requirements.txt" > /dev/null 2>&1; then
                log "⚠️  Potentially vulnerable dependency: $pkg"
                return 1
            fi
        done
    fi
    
    return 0
}

# ツール引数から編集されたファイルを取得
if [[ -n "${CLAUDE_TOOL_ARGS:-}" ]]; then
    # JSON形式の引数からfile_pathを抽出
    if echo "$CLAUDE_TOOL_ARGS" | grep -q '"file_path"'; then
        FILE_PATH=$(echo "$CLAUDE_TOOL_ARGS" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
        
        if [[ -n "$FILE_PATH" ]]; then
            log "Checking file for security issues: $FILE_PATH"
            
            # Secret scanning
            if ! check_secrets "$FILE_PATH"; then
                log "❌ Security check failed: secrets detected in $FILE_PATH"
                exit 2
            fi
            
            # プロジェクトディレクトリの依存関係チェック
            PROJECT_DIR="$(dirname "$FILE_PATH")"
            while [[ "$PROJECT_DIR" != "/" && "$PROJECT_DIR" != "." ]]; do
                if [[ -f "$PROJECT_DIR/requirements.txt" || -f "$PROJECT_DIR/pyproject.toml" ]]; then
                    if ! check_dependencies "$PROJECT_DIR"; then
                        log "❌ Security check failed: vulnerable dependencies in $PROJECT_DIR"
                        exit 2
                    fi
                    break
                fi
                PROJECT_DIR="$(dirname "$PROJECT_DIR")"
            done
            
            log "✅ Security check passed for: $FILE_PATH"
        fi
    fi
fi

log "Security check completed successfully"
exit 0