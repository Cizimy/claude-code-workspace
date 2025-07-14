#!/bin/bash

# TDD Guard Hook - PreToolUse
# Purpose: Prevent source code editing without corresponding test changes
# Exit Code 2: Block the tool execution
# Exit Code 0: Allow the tool execution

set -euo pipefail

# 設定
readonly SCRIPT_NAME="tdd-guard.sh"
readonly LOG_FILE="/tmp/claude-hooks.log"
readonly WORKSPACE_ROOT="/home/kenic/projects"

# ログ関数
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$SCRIPT_NAME] $1" | tee -a "$LOG_FILE"
}

# Hook情報を取得（Claude Codeが提供する環境変数）
readonly TOOL_NAME="${CLAUDE_TOOL_NAME:-unknown}"
readonly TOOL_ARGS="${CLAUDE_TOOL_ARGS:-}"

log_message "TDD Guard activated: tool=$TOOL_NAME"

# Write/Edit ツールの場合のみチェック
if [[ "$TOOL_NAME" != "Write" && "$TOOL_NAME" != "Edit" && "$TOOL_NAME" != "MultiEdit" ]]; then
    log_message "Non-code editing tool, allowing: $TOOL_NAME"
    exit 0
fi

# 編集対象ファイルを解析
extract_file_path() {
    local args="$1"
    # JSON形式の引数からfile_pathを抽出（簡易的）
    echo "$args" | grep -o '"file_path":\s*"[^"]*"' | cut -d'"' -f4 | head -1
}

readonly TARGET_FILE=$(extract_file_path "$TOOL_ARGS")

if [[ -z "$TARGET_FILE" ]]; then
    log_message "Could not extract target file from args, allowing"
    exit 0
fi

log_message "Checking TDD compliance for: $TARGET_FILE"

# テスト対象外ファイルの除外
is_test_exempt() {
    local file="$1"
    
    # テストファイル自体は除外
    [[ "$file" =~ test.*\.(py|js|ts|java|go|rs)$ ]] && return 0
    [[ "$file" =~ .*test\.(py|js|ts|java|go|rs)$ ]] && return 0
    [[ "$file" =~ spec.*\.(py|js|ts|java|go|rs)$ ]] && return 0
    
    # 設定ファイル・ドキュメントは除外
    [[ "$file" =~ \.(md|txt|yml|yaml|json|xml|toml|ini|conf)$ ]] && return 0
    
    # CLAUDEディレクトリは除外
    [[ "$file" =~ \.claude/ ]] && return 0
    
    # Governance ディレクトリは除外
    [[ "$file" =~ governance/ ]] && return 0
    
    return 1
}

if is_test_exempt "$TARGET_FILE"; then
    log_message "File is exempt from TDD checks: $TARGET_FILE"
    exit 0
fi

# 実装ファイルの場合、対応するテストファイルの存在・更新を確認
check_test_file_updates() {
    local impl_file="$1"
    local project_root
    
    # プロジェクトルートを特定
    if [[ "$impl_file" =~ danbooru_advanced_wildcard ]]; then
        project_root="$WORKSPACE_ROOT/danbooru_advanced_wildcard"
    elif [[ "$impl_file" =~ pdi ]]; then
        project_root="$WORKSPACE_ROOT/pdi"
        # VBAプロジェクトはTDDチェックを緩和
        log_message "VBA project detected, relaxing TDD requirements"
        return 0
    else
        log_message "Unknown project, applying strict TDD"
        project_root="$WORKSPACE_ROOT"
    fi
    
    # 最近のテストファイル変更を確認（過去30分以内）
    local recent_test_changes
    recent_test_changes=$(find "$project_root" -name "*test*.py" -o -name "*test*.js" -o -name "*test*.ts" -o -name "*test*.java" -o -name "*test*.go" -o -name "*test*.rs" -o -name "*spec*.py" -o -name "*spec*.js" -o -name "*spec*.ts" | xargs ls -lt 2>/dev/null | head -5)
    
    if [[ -n "$recent_test_changes" ]]; then
        log_message "Recent test file changes detected, allowing implementation change"
        return 0
    fi
    
    # Gitでの変更を確認
    cd "$project_root" || return 1
    
    # 未コミットのテストファイル変更があるかチェック
    local staged_tests
    staged_tests=$(git diff --cached --name-only | grep -E "(test|spec)" || true)
    
    local unstaged_tests  
    unstaged_tests=$(git diff --name-only | grep -E "(test|spec)" || true)
    
    if [[ -n "$staged_tests" || -n "$unstaged_tests" ]]; then
        log_message "Git shows test file changes (staged: '$staged_tests', unstaged: '$unstaged_tests'), allowing"
        return 0
    fi
    
    return 1
}

# TDDチェック実行
if ! check_test_file_updates "$TARGET_FILE"; then
    log_message "TDD VIOLATION: No recent test changes detected for $TARGET_FILE"
    echo "🚫 TDD Guard: テストコードの変更なしに実装ファイルを変更することはできません。" >&2
    echo "" >&2
    echo "以下のいずれかを実行してください:" >&2
    echo "1. 対応するテストファイルを先に作成・更新する" >&2
    echo "2. テスト駆動開発（TDD）の手順に従う:" >&2
    echo "   - Red: 失敗するテストを書く" >&2
    echo "   - Green: テストを通す最小限の実装" >&2
    echo "   - Refactor: コードを改善" >&2
    echo "" >&2
    echo "詳細: $(basename "$TARGET_FILE") の変更には対応するテストが必要です。" >&2
    
    exit 2
fi

log_message "TDD compliance check passed for: $TARGET_FILE"
exit 0