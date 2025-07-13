#!/bin/bash
# Sample Project Test Runner - プロジェクト固有のテスト実行スクリプト

set -euo pipefail

readonly SCRIPT_NAME="test-runner.sh"
readonly LOG_FILE="/tmp/claude-hooks.log"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$SCRIPT_NAME] $1" | tee -a "$LOG_FILE"
}

log_message "Sample Project Test Runner activated"

# プロジェクトタイプの自動検出
detect_project_type() {
    if [ -f "package.json" ]; then
        echo "node"
    elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
        echo "python"
    elif [ -f "go.mod" ]; then
        echo "go"
    else
        echo "unknown"
    fi
}

# テスト実行
run_tests() {
    local project_type="$1"
    
    case "$project_type" in
        "node")
            log_message "Running Node.js tests..."
            if [ -f "package.json" ]; then
                if npm run test 2>/dev/null; then
                    log_message "✅ Node.js tests passed"
                    return 0
                else
                    log_message "❌ Node.js tests failed"
                    return 1
                fi
            else
                log_message "⚠️ package.json not found, skipping tests"
                return 0
            fi
            ;;
        "python")
            log_message "Running Python tests..."
            if command -v pytest >/dev/null 2>&1; then
                if pytest tests/ --cov=src --cov-report=term-missing 2>/dev/null; then
                    log_message "✅ Python tests passed"
                    return 0
                else
                    log_message "❌ Python tests failed"
                    return 1
                fi
            else
                log_message "⚠️ pytest not available, skipping tests"
                return 0
            fi
            ;;
        "go")
            log_message "Running Go tests..."
            if go test ./... -cover -v 2>/dev/null; then
                log_message "✅ Go tests passed"
                return 0
            else
                log_message "❌ Go tests failed"
                return 1
            fi
            ;;
        *)
            log_message "⚠️ Unknown project type, no tests executed"
            return 0
            ;;
    esac
}

# メイン実行
main() {
    local project_type
    project_type=$(detect_project_type)
    
    log_message "Detected project type: $project_type"
    
    if run_tests "$project_type"; then
        log_message "✅ Sample Project test runner completed successfully"
        exit 0
    else
        log_message "❌ Sample Project test runner failed"
        exit 1
    fi
}

main "$@"