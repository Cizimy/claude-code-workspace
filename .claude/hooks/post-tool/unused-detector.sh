#!/bin/bash

# Unused Code Detector Hook - PostToolUse
# Purpose: Detect and report unused functions, variables, and imports after code changes
# Exit Code 2: Block completion (force Claude to clean up)
# Exit Code 0: Allow completion

set -euo pipefail

# 設定
readonly SCRIPT_NAME="unused-detector.sh"
readonly LOG_FILE="/tmp/claude-hooks.log"
readonly WORKSPACE_ROOT="/home/kenic/projects"

# ログ関数
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$SCRIPT_NAME] $1" | tee -a "$LOG_FILE"
}

# Hook情報を取得
readonly TOOL_NAME="${CLAUDE_TOOL_NAME:-unknown}"
readonly TOOL_ARGS="${CLAUDE_TOOL_ARGS:-}"
readonly TOOL_RESULT="${CLAUDE_TOOL_RESULT:-}"

log_message "Unused code detector activated: tool=$TOOL_NAME"

# コード編集系ツールの場合のみチェック
if [[ "$TOOL_NAME" != "Write" && "$TOOL_NAME" != "Edit" && "$TOOL_NAME" != "MultiEdit" ]]; then
    log_message "Non-code editing tool, skipping unused detection: $TOOL_NAME"
    exit 0
fi

# 編集対象ファイルを解析
extract_file_path() {
    local args="$1"
    echo "$args" | grep -o '"file_path":\s*"[^"]*"' | cut -d'"' -f4 | head -1
}

readonly TARGET_FILE=$(extract_file_path "$TOOL_ARGS")

if [[ -z "$TARGET_FILE" ]]; then
    log_message "Could not extract target file, skipping"
    exit 0
fi

log_message "Checking for unused code in: $TARGET_FILE"

# 対象外ファイルの除外
is_analysis_exempt() {
    local file="$1"
    
    # テストファイルは緩和（テスト用のヘルパー関数等があるため）
    [[ "$file" =~ test.*\.(py|js|ts)$ ]] && return 0
    [[ "$file" =~ .*test\.(py|js|ts)$ ]] && return 0
    [[ "$file" =~ spec.*\.(py|js|ts)$ ]] && return 0
    
    # 設定ファイル・ドキュメントは除外
    [[ "$file" =~ \.(md|txt|yml|yaml|json|xml|toml|ini|conf)$ ]] && return 0
    
    # CLAUDEディレクトリは除外
    [[ "$file" =~ \.claude/ ]] && return 0
    
    # Governance ディレクトリは除外
    [[ "$file" =~ governance/ ]] && return 0
    
    # VBAファイルは除外（解析ツールの制限）
    [[ "$file" =~ \.(bas|txt)$ ]] && [[ "$file" =~ pdi/ ]] && return 0
    
    return 1
}

if is_analysis_exempt "$TARGET_FILE"; then
    log_message "File is exempt from unused code analysis: $TARGET_FILE"
    exit 0
fi

# プロジェクトルートを特定
get_project_root() {
    local file="$1"
    
    if [[ "$file" =~ danbooru_advanced_wildcard ]]; then
        echo "$WORKSPACE_ROOT/danbooru_advanced_wildcard"
    elif [[ "$file" =~ pdi ]]; then
        echo "$WORKSPACE_ROOT/pdi"
    else
        echo "$WORKSPACE_ROOT"
    fi
}

readonly PROJECT_ROOT=$(get_project_root "$TARGET_FILE")
cd "$PROJECT_ROOT" || {
    log_message "Could not change to project root: $PROJECT_ROOT"
    exit 0
}

# 言語別の未使用コード検出
detect_unused_python() {
    local file="$1"
    local issues=()
    
    # vulture（未使用コード検出ツール）を使用
    if command -v vulture >/dev/null 2>&1; then
        log_message "Running vulture analysis on $file"
        local vulture_output
        vulture_output=$(vulture "$file" 2>/dev/null || true)
        
        if [[ -n "$vulture_output" ]]; then
            while IFS= read -r line; do
                issues+=("$line")
            done <<< "$vulture_output"
        fi
    else
        # 簡易的な検出（vulture未インストール時）
        log_message "vulture not available, using basic detection for $file"
        
        # 基本的な未使用関数検出
        local unused_functions
        unused_functions=$(grep -n "^def " "$file" | while read -r line; do
            local func_name
            func_name=$(echo "$line" | sed 's/.*def \([^(]*\).*/\1/')
            if [[ -n "$func_name" && "$func_name" != "main" && "$func_name" != "__init__" ]]; then
                # ファイル内で関数が使用されているかチェック
                if ! grep -q "$func_name" "$file" | grep -v "^def $func_name"; then
                    echo "Unused function: $func_name (line $(echo "$line" | cut -d: -f1))"
                fi
            fi
        done)
        
        if [[ -n "$unused_functions" ]]; then
            issues+=("$unused_functions")
        fi
    fi
    
    printf '%s\n' "${issues[@]}"
}

detect_unused_javascript() {
    local file="$1"
    local issues=()
    
    # ESLint with unused rules
    if command -v eslint >/dev/null 2>&1; then
        log_message "Running ESLint analysis on $file"
        local eslint_output
        eslint_output=$(eslint "$file" --rule 'no-unused-vars: error' --rule 'no-unreachable: error' --format compact 2>/dev/null || true)
        
        if [[ -n "$eslint_output" ]]; then
            issues+=("$eslint_output")
        fi
    else
        log_message "ESLint not available for $file"
    fi
    
    printf '%s\n' "${issues[@]}"
}

# メイン検出ロジック
detect_unused_code() {
    local file="$1"
    local file_ext="${file##*.}"
    
    case "$file_ext" in
        py)
            detect_unused_python "$file"
            ;;
        js|ts)
            detect_unused_javascript "$file"
            ;;
        *)
            log_message "Unsupported file type for unused detection: $file_ext"
            return 0
            ;;
    esac
}

# 未使用コード検出実行
readonly UNUSED_ISSUES=$(detect_unused_code "$TARGET_FILE")

if [[ -n "$UNUSED_ISSUES" ]]; then
    log_message "UNUSED CODE DETECTED in $TARGET_FILE:"
    log_message "$UNUSED_ISSUES"
    
    echo "⚠️  未使用コードが検出されました: $(basename "$TARGET_FILE")" >&2
    echo "" >&2
    echo "検出された問題:" >&2
    echo "$UNUSED_ISSUES" >&2
    echo "" >&2
    echo "対応方法:" >&2
    echo "1. 未使用の関数・変数を削除する（YAGNI原則に従う）" >&2
    echo "2. 使用する予定がある場合はテストコードで使用例を示す" >&2
    echo "3. 意図的に残す場合はコメントで理由を明記する" >&2
    echo "" >&2
    echo "YAGNI (You Aren't Gonna Need It) 原則:" >&2
    echo "現在必要でないコードは実装しない・削除する" >&2
    
    exit 2
fi

log_message "No unused code detected in: $TARGET_FILE"
exit 0