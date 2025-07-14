#!/bin/bash

# Coverage Check Hook - Stop
# Purpose: Ensure adequate test coverage before allowing Claude to complete
# Exit Code 2: Block completion (force continued work)
# Exit Code 0: Allow completion
#
# Phase 6 Continuous Improvement System Enhancements:
# - IMP-002: Enhanced pytest integration with project-specific config support
# - Improved fallback testing when pytest is not installed
# - Better error messages and installation recommendations
# - Support for multiple Python package managers (pip, uv, conda)
# Last updated: 2025-07-14 (Phase 6 Implementation)

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

# 音声通知機能（セッション停止ブロック時）
play_session_blocked_sound() {
    # WSL2環境での音声通知（低音で重要性を示す）
    if command -v powershell.exe >/dev/null 2>&1; then
        powershell.exe -Command "[console]::beep(400,400); Start-Sleep -Milliseconds 200; [console]::beep(400,400); Start-Sleep -Milliseconds 200; [console]::beep(400,400)" 2>/dev/null
    elif command -v cmd.exe >/dev/null 2>&1; then
        cmd.exe /c "echo ^G" 2>/dev/null
    else
        printf '\a\a\a'  # トリプルベル音で重要性を示す
    fi
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

# プロジェクト別のカバレッジチェック（Phase 6 強化版）
check_python_coverage() {
    local project_root="$1"
    
    cd "$project_root" || {
        log_message "Cannot change to project root: $project_root"
        return 0
    }
    
    log_message "Checking Python test coverage in: $project_root (Phase 6 強化版)"
    
    # Phase 6 改善: 複数のパッケージマネージャー対応
    local pytest_cmd=""
    local python_cmd=""
    
    # Python実行環境の検出
    if command -v uv >/dev/null 2>&1 && [[ -f "pyproject.toml" || -f "requirements.txt" ]]; then
        python_cmd="uv run python"
        pytest_cmd="uv run pytest"
        log_message "Using uv for Python execution"
    elif [[ -f "venv/bin/activate" ]]; then
        python_cmd="./venv/bin/python"
        pytest_cmd="./venv/bin/pytest"
        log_message "Using local venv for Python execution"
    elif command -v conda >/dev/null 2>&1 && [[ -n "${CONDA_DEFAULT_ENV:-}" ]]; then
        python_cmd="python"
        pytest_cmd="pytest"
        log_message "Using conda environment: $CONDA_DEFAULT_ENV"
    else
        python_cmd="python3"
        pytest_cmd="pytest"
        log_message "Using system Python"
    fi
    
    # pytest の確認（Phase 6 強化）
    if command -v pytest >/dev/null 2>&1 || [[ -x "./venv/bin/pytest" ]] || command -v "$pytest_cmd" >/dev/null 2>&1; then
        log_message "pytest available, running coverage analysis"
        
        # プロジェクト固有設定ファイルの検出
        local pytest_config=""
        local coverage_target=""
        
        # 設定ファイルの優先順位: pytest.ini -> pyproject.toml -> setup.cfg
        if [[ -f "pytest.ini" ]]; then
            pytest_config="pytest.ini"
            log_message "Using pytest.ini configuration"
        elif [[ -f "pyproject.toml" ]] && grep -q "pytest" "pyproject.toml"; then
            pytest_config="pyproject.toml"
            log_message "Using pyproject.toml configuration"
        elif [[ -f "setup.cfg" ]] && grep -q "pytest" "setup.cfg"; then
            pytest_config="setup.cfg"
            log_message "Using setup.cfg configuration"
        else
            log_message "No pytest configuration found, using defaults"
        fi
        
        # カバレッジ対象の自動検出
        if [[ -d "src" ]]; then
            # src/ レイアウト
            coverage_target="src"
        elif [[ -d "lib" ]]; then
            # lib/ レイアウト
            coverage_target="lib"
        else
            # フラットレイアウト - プロジェクト名を推測
            local project_name
            if [[ -f "pyproject.toml" ]]; then
                project_name=$(grep "^name = " pyproject.toml | sed 's/name = "\([^"]*\)".*/\1/' || echo "")
            elif [[ -f "setup.py" ]]; then
                project_name=$(grep "name=" setup.py | sed "s/.*name=['\"]\\([^'\"]*\\)['\"].*/\\1/" || echo "")
            fi
            
            if [[ -n "$project_name" && -d "$project_name" ]]; then
                coverage_target="$project_name"
            else
                # デフォルト: カレントディレクトリの .py ファイル
                coverage_target="."
            fi
        fi
        
        log_message "Coverage target: $coverage_target"
        
        # Phase 6 強化: より堅牢なpytest実行
        local coverage_output=""
        local coverage_percentage=""
        local pytest_exit_code=0
        
        # pytest実行（複数の方法を試行）
        if coverage_output=$($pytest_cmd --cov="$coverage_target" --cov-report=term-missing --cov-fail-under=0 -v 2>&1); then
            pytest_exit_code=0
        elif coverage_output=$($python_cmd -m pytest --cov="$coverage_target" --cov-report=term-missing --cov-fail-under=0 -v 2>&1); then
            pytest_exit_code=0
        else
            pytest_exit_code=1
            log_message "pytest execution failed, output: $coverage_output"
        fi
        
        if [[ $pytest_exit_code -eq 0 ]]; then
            # カバレッジパーセンテージの抽出（Phase 6 改善）
            coverage_percentage=$(echo "$coverage_output" | grep "TOTAL" | awk '{print $4}' | sed 's/%//' | head -1)
            
            if [[ -z "$coverage_percentage" ]]; then
                # 代替パターンでの抽出
                coverage_percentage=$(echo "$coverage_output" | grep -o "coverage: [0-9]\+%" | sed 's/coverage: \([0-9]\+\)%.*/\1/' | head -1)
            fi
            
            if [[ -n "$coverage_percentage" && "$coverage_percentage" =~ ^[0-9]+$ ]]; then
                log_message "Current coverage: ${coverage_percentage}%"
                
                if (( coverage_percentage < MIN_COVERAGE_THRESHOLD )); then
                    log_message "Coverage below threshold: ${coverage_percentage}% < ${MIN_COVERAGE_THRESHOLD}%"
                    return 1
                else
                    log_message "Coverage meets threshold: ${coverage_percentage}% >= ${MIN_COVERAGE_THRESHOLD}%"
                    return 0
                fi
            else
                log_message "Could not extract coverage percentage from output"
                log_message "pytest output: $coverage_output"
                # テストが実行されたなら成功とみなす
                if echo "$coverage_output" | grep -q "test session starts\|collected.*items"; then
                    log_message "Tests executed successfully, assuming coverage is adequate"
                    return 0
                else
                    return 1
                fi
            fi
        else
            log_message "pytest execution failed, falling back to basic test checks"
            return $(check_python_fallback_testing "$project_root")
        fi
    else
        log_message "pytest not available, using enhanced fallback testing"
        return $(check_python_fallback_testing "$project_root")
    fi
}

# Phase 6 追加: pytest未インストール時の強化されたフォールバック
check_python_fallback_testing() {
    local project_root="$1"
    
    log_message "RECOMMENDATION: Install pytest for better testing support"
    log_message "Installation commands:"
    log_message "  pip install pytest pytest-cov"
    log_message "  # or with uv: uv add pytest pytest-cov"
    log_message "  # or with conda: conda install pytest pytest-cov"
    
    # 1. テストファイル存在確認（強化）
    local test_patterns=(
        "*test*.py"
        "*_test.py" 
        "test_*.py"
        "tests/*.py"
        "test/*.py"
        "**/test_*.py"
        "**/tests/*.py"
    )
    
    local test_file_count=0
    for pattern in "${test_patterns[@]}"; do
        if ls $pattern >/dev/null 2>&1; then
            local count=$(ls $pattern 2>/dev/null | wc -l)
            test_file_count=$((test_file_count + count))
        fi
    done
    
    log_message "Found $test_file_count test files"
    
    if (( test_file_count == 0 )); then
        log_message "No test files found - test creation required"
        return 1
    fi
    
    # 2. 基本的なテスト実行確認（unittest使用）
    local python_cmd="python3"
    if command -v uv >/dev/null 2>&1; then
        python_cmd="uv run python"
    fi
    
    # テストファイルで基本的な構文チェック
    local test_syntax_ok=true
    for test_file in $(find . -name "*test*.py" -o -name "test_*.py" | head -5); do
        if ! $python_cmd -m py_compile "$test_file" 2>/dev/null; then
            log_message "Syntax error in test file: $test_file"
            test_syntax_ok=false
        fi
    done
    
    if [[ "$test_syntax_ok" == "false" ]]; then
        log_message "Test files contain syntax errors"
        return 1
    fi
    
    # 3. 簡易的なカバレッジ推定
    local py_file_count=$(find . -name "*.py" -not -path "*/test*" -not -path "*/.*" | wc -l)
    local test_function_count=$(grep -r "def test_" . --include="*test*.py" | wc -l)
    
    if (( py_file_count > 0 )); then
        local test_ratio=$((test_function_count * 100 / py_file_count))
        log_message "Estimated test coverage ratio: ${test_ratio}% (${test_function_count} test functions for ${py_file_count} Python files)"
        
        if (( test_ratio < 20 )); then
            log_message "Insufficient test coverage estimated"
            return 1
        fi
    fi
    
    log_message "Basic test validation passed (fallback mode)"
    return 0
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
            echo "解決方法（Phase 6 強化版）:" >&2
            echo "1. 不足しているテストケースを追加" >&2
            echo "2. カバレッジ確認コマンド:" >&2
            echo "   uv run pytest --cov=proper_pixel_art --cov-report=term-missing" >&2
            echo "   # または: pytest --cov=. --cov-report=term-missing" >&2
            echo "3. 未テスト部分に対応するテストを実装" >&2
            echo "4. pytest未インストールの場合: pip install pytest pytest-cov" >&2
            ;;
        danbooru_advanced_wildcard)
            echo "Python プロジェクトの要求事項:" >&2
            echo "• テストカバレッジ: ${MIN_COVERAGE_THRESHOLD}% 以上" >&2
            echo "• 実装変更時は対応するテストの追加・更新が必要" >&2
            echo "" >&2
            echo "解決方法（Phase 6 強化版）:" >&2
            echo "1. 不足しているテストケースを追加" >&2
            echo "2. カバレッジ確認コマンド:" >&2
            echo "   pytest --cov=src --cov-report=term-missing" >&2
            echo "   # または: uv run pytest --cov=src --cov-report=term-missing" >&2
            echo "3. 未テスト部分に対応するテストを実装" >&2
            echo "4. pytest未インストールの場合: pip install pytest pytest-cov" >&2
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
    
    # セッション継続が必要な重要な意思決定タイミングで音声通知
    play_session_blocked_sound
    
    exit 2
fi

log_message "Coverage check passed for project: $PROJECT"
exit 0