#!/bin/bash

# Unused Code Detector Hook - PostToolUse
# Purpose: Detect and report unused functions, variables, and imports after code changes
# Exit Code 2: Block completion (force Claude to clean up)
# Exit Code 0: Allow completion
#
# Phase 6 Continuous Improvement System Enhancements:
# - IMP-001: Enhanced vulture integration with project-specific config support
# - Improved fallback detection when vulture is not installed
# - Better error messages and installation recommendations
# Last updated: 2025-07-14 (Phase 6 Implementation)

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
    local filename=$(basename "$file")
    
    # テストファイルは緩和（テスト用のヘルパー関数等があるため）
    [[ "$filename" =~ ^test.*\.(py|js|ts)$ ]] && return 0
    [[ "$filename" =~ .*_test\.(py|js|ts)$ ]] && return 0
    [[ "$filename" =~ ^spec.*\.(py|js|ts)$ ]] && return 0
    
    # テストディレクトリ内のファイルは緩和
    [[ "$file" =~ /tests?/ ]] && return 0
    [[ "$file" =~ /spec/ ]] && return 0
    
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
    elif [[ "$file" =~ pilot-test ]]; then
        echo "$WORKSPACE_ROOT/projects/pilot-test"
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
    
    # Phase 6 継続改善: vulture統合強化 (IMP-001対応)
    # Try to find vulture in project's virtual environment first
    local vulture_cmd=""
    if [[ -f "$PROJECT_ROOT/venv/bin/vulture" ]]; then
        vulture_cmd="$PROJECT_ROOT/venv/bin/vulture"
        log_message "Found vulture in project venv: $vulture_cmd"
    elif command -v vulture >/dev/null 2>&1; then
        vulture_cmd="vulture"
        log_message "Found vulture in system PATH: $vulture_cmd"
    fi

    if [[ -n "$vulture_cmd" ]]; then
        log_message "Running vulture analysis on $file (Phase 6 強化版)"
        
        # プロジェクトルートの設定ファイル確認
        local vulture_config=""
        if [[ -f "$PROJECT_ROOT/.vulture" ]]; then
            vulture_config="$PROJECT_ROOT/.vulture"
            log_message "Using project-specific vulture config: $vulture_config"
        elif [[ -f "$PROJECT_ROOT/.vulture.txt" ]]; then
            vulture_config="$PROJECT_ROOT/.vulture.txt"
            log_message "Using legacy vulture config: $vulture_config"
        elif [[ -f "$WORKSPACE_ROOT/.vulture" ]]; then
            vulture_config="$WORKSPACE_ROOT/.vulture"
            log_message "Using workspace-level vulture config: $vulture_config"
        fi
        
        # vulture実行（設定ファイル考慮）
        local vulture_output
        if [[ -n "$vulture_config" ]]; then
            vulture_output=$("$vulture_cmd" "$file" --config "$vulture_config" 2>/dev/null || true)
        else
            # デフォルト設定で実行
            vulture_output=$("$vulture_cmd" "$file" --min-confidence 80 2>/dev/null || true)
        fi
        
        if [[ -n "$vulture_output" ]]; then
            log_message "vulture detected unused code in $file"
            while IFS= read -r line; do
                # 出力をより解析しやすい形式に変換
                if [[ "$line" =~ ^([^:]+):([0-9]+):[[:space:]]*(.+) ]]; then
                    local file_path="${BASH_REMATCH[1]}"
                    local line_num="${BASH_REMATCH[2]}"
                    local issue_desc="${BASH_REMATCH[3]}"
                    issues+=("Line $line_num: $issue_desc")
                else
                    issues+=("$line")
                fi
            done <<< "$vulture_output"
        else
            log_message "vulture: No unused code detected in $file"
        fi
    else
        # Phase 6 改善: vulture未インストール時の強化された代替検出
        log_message "vulture not available, using enhanced fallback detection for $file"
        log_message "RECOMMENDATION: Install vulture for better unused code detection (pip install vulture)"
        
        # 1. 未使用関数検出（改良版）
        local unused_functions
        unused_functions=$(detect_unused_python_functions "$file")
        if [[ -n "$unused_functions" ]]; then
            issues+=("$unused_functions")
        fi
        
        # 2. 未使用インポート検出（基本版）
        local unused_imports
        unused_imports=$(detect_unused_python_imports "$file")
        if [[ -n "$unused_imports" ]]; then
            issues+=("$unused_imports")
        fi
        
        # 3. 未使用変数検出（基本版）
        local unused_vars
        unused_vars=$(detect_unused_python_variables "$file")
        if [[ -n "$unused_vars" ]]; then
            issues+=("$unused_vars")
        fi
    fi
    
    printf '%s\n' "${issues[@]}"
}

# Phase 6 追加: vulture未インストール時の強化された代替検出関数群
detect_unused_python_functions() {
    local file="$1"
    local temp_result=""
    
    # 関数定義の抽出
    grep -n "^[[:space:]]*def " "$file" | while IFS=: read -r line_num line_content; do
        local func_name
        func_name=$(echo "$line_content" | sed -E 's/^[[:space:]]*def[[:space:]]+([^(]+).*/\1/')
        
        # 特殊関数・メソッドの除外
        if [[ "$func_name" =~ ^(main|__init__|__str__|__repr__|__eq__|test_.*|setUp|tearDown)$ ]]; then
            continue
        fi
        
        # ファイル内での使用確認（関数定義行以外）
        local usage_count
        usage_count=$(grep -n "$func_name" "$file" | grep -v "^$line_num:" | wc -l)
        
        if [[ $usage_count -eq 0 ]]; then
            echo "Unused function: $func_name (line $line_num)"
        fi
    done
}

detect_unused_python_imports() {
    local file="$1"
    
    # import文の抽出
    grep -n "^[[:space:]]*import\|^[[:space:]]*from.*import" "$file" | while IFS=: read -r line_num line_content; do
        # 単純なimport文の処理
        if [[ "$line_content" =~ ^[[:space:]]*import[[:space:]]+([^#]+) ]]; then
            local imports="${BASH_REMATCH[1]}"
            # カンマ区切りの処理
            echo "$imports" | tr ',' '\n' | while read -r module; do
                module=$(echo "$module" | xargs)  # トリム
                if [[ -n "$module" ]]; then
                    # モジュール使用確認（import行以外）
                    local usage_count
                    usage_count=$(grep -n "$module" "$file" | grep -v "^$line_num:" | wc -l)
                    if [[ $usage_count -eq 0 ]]; then
                        echo "Potentially unused import: $module (line $line_num)"
                    fi
                fi
            done
        fi
    done
}

detect_unused_python_variables() {
    local file="$1"
    
    # グローバル変数の検出（簡易版）
    grep -n "^[[:space:]]*[A-Z_][A-Z0-9_]*[[:space:]]*=" "$file" | while IFS=: read -r line_num line_content; do
        local var_name
        var_name=$(echo "$line_content" | sed -E 's/^[[:space:]]*([A-Z_][A-Z0-9_]*)[[:space:]]*=.*/\1/')
        
        if [[ -n "$var_name" ]]; then
            # 変数使用確認（定義行以外）
            local usage_count
            usage_count=$(grep -n "$var_name" "$file" | grep -v "^$line_num:" | wc -l)
            
            if [[ $usage_count -eq 0 ]]; then
                echo "Potentially unused variable: $var_name (line $line_num)"
            fi
        fi
    done
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