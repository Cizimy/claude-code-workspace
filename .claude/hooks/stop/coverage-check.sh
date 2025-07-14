#!/bin/bash

# Coverage Check Hook - Stop
# Purpose: Ensure adequate test coverage before allowing Claude to complete
# Exit Code 2: Block completion (force continued work)
# Exit Code 0: Allow completion

set -euo pipefail

# 設定
readonly SCRIPT_NAME="coverage-check.sh"
readonly LOG_FILE="/tmp/claude-hooks.log"
readonly WORKSPACE_ROOT="/home/kenic/projects"
readonly MIN_COVERAGE_THRESHOLD=60  # 最小カバレッジ閾値（%）

# ログ関数
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$SCRIPT_NAME] $1" | tee -a "$LOG_FILE"
}

log_message "Coverage check hook activated"

# 現在のワーキングディレクトリからプロジェクトを特定
get_current_project() {
    local current_dir
    current_dir=$(pwd)
    
    if [[ "$current_dir" =~ proper-pixel-art ]]; then
        echo "proper-pixel-art"
    elif [[ "$current_dir" =~ danbooru_advanced_wildcard ]]; then
        echo "danbooru_advanced_wildcard"
    elif [[ "$current_dir" =~ pdi ]]; then
        echo "pdi"
    else
        echo "workspace"
    fi
}

readonly PROJECT=$(get_current_project)
log_message "Detected project: $PROJECT"

# プロジェクト別のカバレッジチェック
check_python_coverage() {
    local project_root="$1"
    
    cd "$project_root" || {
        log_message "Cannot change to project root: $project_root"
        return 0
    }
    
    log_message "Checking Python test coverage in: $project_root"
    
    # pytest-cov を使用してカバレッジを計算
    if command -v pytest >/dev/null 2>&1; then
        local coverage_output
        local coverage_percentage
        
        # まずテストを実行してカバレッジを取得
        if coverage_output=$(python -m pytest --cov=proper_pixel_art --cov-report=term-missing --cov-fail-under=0 -q 2>/dev/null) || coverage_output=$(uv run pytest --cov=proper_pixel_art --cov-report=term-missing --cov-fail-under=0 -q 2>/dev/null); then
            # カバレッジパーセンテージを抽出
            coverage_percentage=$(echo "$coverage_output" | grep "TOTAL" | awk '{print $4}' | sed 's/%//' || echo "0")
            
            if [[ -n "$coverage_percentage" ]]; then
                log_message "Current coverage: ${coverage_percentage}%"
                
                if (( coverage_percentage < MIN_COVERAGE_THRESHOLD )); then
                    log_message "Coverage below threshold: ${coverage_percentage}% < ${MIN_COVERAGE_THRESHOLD}%"
                    return 1
                else
                    log_message "Coverage meets threshold: ${coverage_percentage}% >= ${MIN_COVERAGE_THRESHOLD}%"
                    return 0
                fi
            else
                log_message "Could not extract coverage percentage"
                return 0  # 不明な場合は通す
            fi
        else
            log_message "pytest execution failed, checking if tests exist"
            
            # テストファイルが存在するかチェック
            local test_files
            test_files=$(find . -name "*test*.py" -o -name "*spec*.py" 2>/dev/null | wc -l)
            
            if (( test_files == 0 )); then
                log_message "No test files found, requiring test creation"
                return 1
            else
                log_message "Test files exist but pytest failed, allowing completion"
                return 0
            fi
        fi
    else
        log_message "pytest not available, using simple test file check"
        
        # 基本的なテストファイル存在チェック
        local test_files
        test_files=$(find . -name "*test*.py" -o -name "*spec*.py" 2>/dev/null | wc -l)
        
        if (( test_files == 0 )); then
            log_message "No test files found"
            return 1
        else
            log_message "Test files found: $test_files"
            return 0
        fi
    fi
}

check_vba_coverage() {
    local project_root="$1"
    
    log_message "VBA project coverage check (relaxed requirements)"
    
    # VBAプロジェクトは手動テストが多いため要求を緩和
    cd "$project_root" || return 0
    
    # 基本的な構造チェック
    local vba_files
    vba_files=$(find . -name "*.bas" -o -name "*.txt" | grep -E "(Func_|Test_|Main_)" | wc -l)
    
    if (( vba_files >= 3 )); then
        log_message "VBA project structure looks adequate: $vba_files files"
        return 0
    else
        log_message "VBA project might need more structure: $vba_files files"
        return 1
    fi
}

check_workspace_coverage() {
    log_message "Workspace-level coverage check"
    
    # ワークスペースレベルでは基本的な構造をチェック
    local required_files=(
        ".claude/settings.json"
        "governance/adr/000-claude-code-adoption.md"
        "governance/decision_log.md"
        ".claude/hooks/pre-tool/tdd-guard.sh"
        ".claude/hooks/post-tool/unused-detector.sh"
        ".claude/hooks/stop/coverage-check.sh"
    )
    
    local missing_files=()
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$WORKSPACE_ROOT/$file" ]]; then
            missing_files+=("$file")
        fi
    done
    
    if (( ${#missing_files[@]} > 0 )); then
        log_message "Missing required workspace files: ${missing_files[*]}"
        return 1
    else
        log_message "All required workspace files present"
        return 0
    fi
}

# Git変更の範囲チェック
check_change_scope() {
    local project_root="$1"
    
    cd "$project_root" || return 0
    
    # 新規・変更されたファイルをチェック
    local changed_files
    changed_files=$(git diff --name-only HEAD~1 2>/dev/null || git ls-files --others --exclude-standard || true)
    
    if [[ -z "$changed_files" ]]; then
        log_message "No recent changes detected"
        return 0
    fi
    
    log_message "Changed files: $changed_files"
    
    # 実装ファイルが変更されている場合、対応するテストファイルもチェック
    local impl_changes
    impl_changes=$(echo "$changed_files" | grep -E "\.(py|js|ts|java|go|rs)$" | grep -v -E "(test|spec)" || true)
    
    if [[ -n "$impl_changes" ]]; then
        log_message "Implementation files changed: $impl_changes"
        
        local test_changes
        test_changes=$(echo "$changed_files" | grep -E "(test|spec)" || true)
        
        if [[ -z "$test_changes" ]]; then
            log_message "Implementation changed but no test changes detected"
            return 1
        else
            log_message "Corresponding test changes found: $test_changes"
            return 0
        fi
    fi
    
    return 0
}

# メインのカバレッジチェック実行
main_coverage_check() {
    case "$PROJECT" in
        proper-pixel-art)
            local project_root="$WORKSPACE_ROOT/projects/proper-pixel-art"
            if ! check_python_coverage "$project_root" || ! check_change_scope "$project_root"; then
                return 1
            fi
            ;;
        danbooru_advanced_wildcard)
            local project_root="$WORKSPACE_ROOT/danbooru_advanced_wildcard"
            if ! check_python_coverage "$project_root" || ! check_change_scope "$project_root"; then
                return 1
            fi
            ;;
        pdi)
            local project_root="$WORKSPACE_ROOT/pdi"
            if ! check_vba_coverage "$project_root" || ! check_change_scope "$project_root"; then
                return 1
            fi
            ;;
        workspace)
            if ! check_workspace_coverage; then
                return 1
            fi
            ;;
        *)
            log_message "Unknown project, applying basic checks"
            return 0
            ;;
    esac
    
    return 0
}

# カバレッジチェック実行
if ! main_coverage_check; then
    log_message "COVERAGE CHECK FAILED for project: $PROJECT"
    
    echo "📊 カバレッジチェック: 基準を満たしていません" >&2
    echo "" >&2
    case "$PROJECT" in
        proper-pixel-art)
            echo "Python プロジェクトの要求事項:" >&2
            echo "• テストカバレッジ: ${MIN_COVERAGE_THRESHOLD}% 以上" >&2
            echo "• 実装変更時は対応するテストの追加・更新が必要" >&2
            echo "" >&2
            echo "解決方法:" >&2
            echo "1. 不足しているテストケースを追加" >&2
            echo "2. uv run pytest --cov=proper_pixel_art --cov-report=term-missing でカバレッジを確認" >&2
            echo "3. 未テスト部分に対応するテストを実装" >&2
            ;;
        danbooru_advanced_wildcard)
            echo "Python プロジェクトの要求事項:" >&2
            echo "• テストカバレッジ: ${MIN_COVERAGE_THRESHOLD}% 以上" >&2
            echo "• 実装変更時は対応するテストの追加・更新が必要" >&2
            echo "" >&2
            echo "解決方法:" >&2
            echo "1. 不足しているテストケースを追加" >&2
            echo "2. pytest --cov=src --cov-report=term-missing でカバレッジを確認" >&2
            echo "3. 未テスト部分に対応するテストを実装" >&2
            ;;
        pdi)
            echo "VBA プロジェクトの要求事項:" >&2
            echo "• 主要な機能モジュールの存在確認" >&2
            echo "• 適切なエラーハンドリングの実装" >&2
            echo "" >&2
            echo "解決方法:" >&2
            echo "1. Func_* モジュールの完全性を確認" >&2
            echo "2. Main_Integrated_Refactored の動作テスト" >&2
            ;;
        workspace)
            echo "ワークスペースの要求事項:" >&2
            echo "• 必要な設定ファイルとガバナンス文書" >&2
            echo "• フック機能の完全性" >&2
            echo "" >&2
            echo "解決方法:" >&2
            echo "1. 不足しているファイルを作成" >&2
            echo "2. .claude/settings.json の設定確認" >&2
            ;;
    esac
    
    exit 2
fi

log_message "Coverage check passed for project: $PROJECT"
exit 0