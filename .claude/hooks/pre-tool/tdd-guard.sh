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

# ADR-003: 憲法リマインダーシステム設定
readonly TOOL_COUNTER_FILE="/tmp/claude-tool-counter"
readonly REMINDER_INTERVAL=20  # 20ツール実行毎にリマインド

# ログ関数
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$SCRIPT_NAME] $1" | tee -a "$LOG_FILE"
}

# ADR-003: 憲法リマインダーシステム
update_tool_counter() {
    local current_count=0
    
    # 現在のカウンターを読み取り
    if [[ -f "$TOOL_COUNTER_FILE" ]]; then
        current_count=$(cat "$TOOL_COUNTER_FILE" 2>/dev/null || echo "0")
    fi
    
    # カウンターを増加
    current_count=$((current_count + 1))
    echo "$current_count" > "$TOOL_COUNTER_FILE"
    
    log_message "Tool execution count: $current_count"
    
    # リマインダー間隔に達した場合
    if (( current_count % REMINDER_INTERVAL == 0 )); then
        show_constitution_reminder "$current_count"
        # カウンターをリセット
        echo "0" > "$TOOL_COUNTER_FILE"
    fi
}

# 音声通知機能（意思決定必要時のみ）
play_reminder_sound() {
    # WSL2環境での音声通知
    if command -v powershell.exe >/dev/null 2>&1; then
        powershell.exe -Command "[console]::beep(600,200); Start-Sleep -Milliseconds 150; [console]::beep(600,200)" 2>/dev/null
    elif command -v cmd.exe >/dev/null 2>&1; then
        cmd.exe /c "echo ^G" 2>/dev/null
    else
        printf '\a'
    fi
}

show_constitution_reminder() {
    local tool_count="$1"
    
    log_message "Constitution reminder triggered after $tool_count tool executions"
    
    # 憲法確認が必要なタイミングで音声通知
    play_reminder_sound
    
    echo "📖 【憲法リマインダー】Claude Code セッション継続中 (${tool_count}ツール実行)" >&2
    echo "" >&2
    echo "🎯 プロジェクト憲法の確認をお願いします：" >&2
    echo "" >&2
    echo "【基本原則】" >&2
    echo "• TDD (テスト駆動開発): 実装前にテスト作成を徹底" >&2
    echo "• YAGNI (You Aren't Gonna Need It): 必要な機能のみ実装" >&2
    echo "• KISS (Keep It Simple, Stupid): シンプルな設計を維持" >&2
    echo "" >&2
    echo "【AI完璧主義症候群対策】" >&2
    echo "• 95%以上の完璧を追求しない（95%で十分）" >&2
    echo "• 推測実装禁止（'将来必要かも'で実装しない）" >&2
    echo "• 大量ドキュメント作成禁止（5ファイル以上同時作成不可）" >&2
    echo "• 長期計画作成禁止（2026年以降の計画は作成しない）" >&2
    echo "" >&2
    echo "📋 詳細は CLAUDE.md を参照してください" >&2
    echo "💡 現在のタスクが憲法に準拠しているか確認をお願いします" >&2
    echo "" >&2
}

# Hook情報を取得（Claude Codeが提供する環境変数）
readonly TOOL_NAME="${CLAUDE_TOOL_NAME:-unknown}"
readonly TOOL_ARGS="${CLAUDE_TOOL_ARGS:-}"

log_message "TDD Guard activated: tool=$TOOL_NAME"

# ADR-003: 憲法リマインダーシステム実行
update_tool_counter

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
    local filename=$(basename "$file")
    
    # テストファイル自体は除外 (ファイル名ベースでチェック)
    [[ "$filename" =~ ^test.*\.(py|js|ts|java|go|rs)$ ]] && return 0
    [[ "$filename" =~ .*_test\.(py|js|ts|java|go|rs)$ ]] && return 0
    [[ "$filename" =~ ^spec.*\.(py|js|ts|java|go|rs)$ ]] && return 0
    
    # テストディレクトリ内のファイルは除外
    [[ "$file" =~ /tests?/ ]] && return 0
    [[ "$file" =~ /spec/ ]] && return 0
    
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
    elif [[ "$impl_file" =~ pilot-test ]]; then
        project_root="$WORKSPACE_ROOT/projects/pilot-test"
        log_message "Pilot test project detected, applying strict TDD"
    else
        log_message "Unknown project, applying strict TDD"
        project_root="$WORKSPACE_ROOT"
    fi
    
    # 最近のテストファイル変更を確認（過去30分以内）
    local recent_test_count
    recent_test_count=$(find "$project_root" -path "*/venv" -prune -o -path "*/node_modules" -prune -o -path "*/.git" -prune -o \( -name "*test*.py" -o -name "*test*.js" -o -name "*test*.ts" -o -name "*test*.java" -o -name "*test*.go" -o -name "*test*.rs" -o -name "*spec*.py" -o -name "*spec*.js" -o -name "*spec*.ts" \) -mmin -30 -print 2>/dev/null | wc -l)
    
    if [[ "$recent_test_count" -gt 0 ]]; then
        log_message "Recent test file changes detected ($recent_test_count files within 30 minutes), allowing implementation change"
        # Log the actual files for debugging
        find "$project_root" -path "*/venv" -prune -o -path "*/node_modules" -prune -o -path "*/.git" -prune -o \( -name "*test*.py" -o -name "*test*.js" -o -name "*test*.ts" -o -name "*test*.java" -o -name "*test*.go" -o -name "*test*.rs" -o -name "*spec*.py" -o -name "*spec*.js" -o -name "*spec*.ts" \) -mmin -30 -print 2>/dev/null | head -3 | while read -r file; do
            [[ -n "$file" ]] && log_message "  Recent test file: $file"
        done
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

# TDD違反時の音声通知
play_tdd_violation_sound() {
    # WSL2環境での音声通知（高音で注意喚起）
    if command -v powershell.exe >/dev/null 2>&1; then
        powershell.exe -Command "[console]::beep(1200,250); Start-Sleep -Milliseconds 100; [console]::beep(1000,250)" 2>/dev/null
    elif command -v cmd.exe >/dev/null 2>&1; then
        cmd.exe /c "echo ^G" 2>/dev/null
    else
        printf '\a\a'  # ダブルベル音
    fi
}

# TDDチェック実行
if ! check_test_file_updates "$TARGET_FILE"; then
    log_message "TDD VIOLATION: No recent test changes detected for $TARGET_FILE"
    
    # TDD違反によるブロック時に音声通知
    play_tdd_violation_sound
    
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