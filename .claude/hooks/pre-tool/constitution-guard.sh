#!/bin/bash

# ADR-003: AI完璧主義防止システム - Constitution Guard Hook
# 大量ドキュメント作成・長期計画・過剰詳細化検出による教育的ブロック

set -euo pipefail

# ログ設定
LOG_FILE="/tmp/claude-hooks.log"
HOOK_NAME="constitution-guard"

# 設定値
MAX_FILES_CREATION=5
MAX_DOCUMENT_LINES=500
CURRENT_YEAR=$(date +%Y)
FUTURE_YEAR_THRESHOLD=$((CURRENT_YEAR + 1))  # 2026年以降をブロック

# ログ出力関数
log_message() {
    local level="$1"
    local message="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$HOOK_NAME] [$level] $message" >> "$LOG_FILE"
}

# 音声通知機能
play_decision_required_sound() {
    # WSL2環境での音声通知
    if command -v powershell.exe >/dev/null 2>&1; then
        powershell.exe -Command "[console]::beep(1000,300); Start-Sleep -Milliseconds 100; [console]::beep(800,300)" 2>/dev/null
    elif command -v cmd.exe >/dev/null 2>&1; then
        cmd.exe /c "echo ^G" 2>/dev/null
    else
        printf '\a\a'  # ダブルベル音で重要性を示す
    fi
}

# 教育的指導メッセージ表示
show_constitution_guidance() {
    local violation_type="$1"
    local details="$2"
    
    # 重要な意思決定が必要なタイミングで音声通知
    play_decision_required_sound
    
    echo "🚫 Constitution Guard: AI完璧主義症候群違反が検出されました"
    echo
    echo "【違反種別】: $violation_type"
    echo "【詳細】: $details"
    echo
    echo "📖 プロジェクト憲法（CLAUDE.md）より："
    echo
    
    case "$violation_type" in
        "大量ドキュメント作成")
            echo "⚠️ 禁止事項: 大量ドキュメント作成禁止（5ファイル以上の同時作成不可）"
            echo
            echo "🔍 自己チェック項目："
            echo "1. 今すぐ使うか？ → NO なら実装しない"
            echo "2. 最もシンプルか？ → NO なら分割検討"
            echo
            echo "📏 推奨対策："
            echo "- 1回の作業では4ファイル以下に制限する"
            echo "- 本当に必要な文書のみ作成する"
            echo "- 複数回に分けて段階的に作成する"
            ;;
        "長期計画作成")
            echo "⚠️ 禁止事項: 長期計画作成禁止（${FUTURE_YEAR_THRESHOLD}年以降の計画は作成しない）"
            echo
            echo "🔍 自己チェック項目："
            echo "1. 今すぐ使うか？ → NO なら実装しない"
            echo "2. 実証されているか？ → NO なら仮説扱い"
            echo
            echo "📏 推奨対策："
            echo "- 当年中の計画に限定する"
            echo "- 具体的なIssueに基づく短期計画のみ"
            echo "- 'roadmap'、'enhancement'等の推測的計画は避ける"
            ;;
        "過剰詳細化")
            echo "⚠️ 禁止事項: 95%以上の完璧を追求しない（95%で十分です）"
            echo
            echo "🔍 自己チェック項目："
            echo "1. 最もシンプルか？ → NO なら分割検討"
            echo "2. 本当に必要か？ → 疑問があれば実装しない"
            echo
            echo "📏 推奨対策："
            echo "- 文書を${MAX_DOCUMENT_LINES}行以下に分割する"
            echo "- 必要最小限の情報のみ記載する"
            echo "- 複数の文書に分けて関心を分離する"
            ;;
    esac
    
    echo
    echo "💡 詳細は CLAUDE.md の「AI完璧主義症候群対策」セクションを参照してください"
    echo "🚨 緊急時のみ: export CLAUDE_HOOKS_DISABLED=true で一時無効化可能"
}

# 除外条件チェック
is_exempt_file() {
    local file="$1"
    
    # テストファイル
    if [[ "$file" =~ test|spec|__tests__ ]]; then
        return 0
    fi
    
    # 設定ファイル
    if [[ "$file" =~ \.(json|yml|yaml|toml|ini|cfg)$ ]]; then
        return 0
    fi
    
    # ガバナンス文書（ADRやミーティング議事録等）
    if [[ "$file" =~ ^governance/ ]]; then
        return 0
    fi
    
    # VBAファイル（言語制約による緩和）
    if [[ "$file" =~ \.(bas|cls|frm|vba)$ ]]; then
        return 0
    fi
    
    # Hookファイル自体
    if [[ "$file" =~ \.claude/hooks/ ]]; then
        return 0
    fi
    
    return 1
}

# 大量ファイル作成検出
check_mass_file_creation() {
    local files=("$@")
    local creation_count=0
    local new_files=()
    
    # 新規作成ファイルをカウント
    for file in "${files[@]}"; do
        if [[ ! -f "$file" ]] && ! is_exempt_file "$file"; then
            creation_count=$((creation_count + 1))
            new_files+=("$file")
        fi
    done
    
    if (( creation_count >= MAX_FILES_CREATION )); then
        local details="同時作成ファイル数: ${creation_count}個 (制限: ${MAX_FILES_CREATION}個未満)"
        details+="\n作成予定ファイル: $(printf '%s, ' "${new_files[@]}" | sed 's/, $//')"
        
        log_message "BLOCK" "Mass file creation detected: $creation_count files"
        show_constitution_guidance "大量ドキュメント作成" "$details"
        return 1
    fi
    
    return 0
}

# 長期計画文書検出
check_long_term_planning() {
    local files=("$@")
    
    for file in "${files[@]}"; do
        if is_exempt_file "$file"; then
            continue
        fi
        
        # ファイル名での検出
        if [[ "$file" =~ (roadmap|enhancement|plan|strategy).*\.md$ ]]; then
            local details="長期計画文書の可能性: $file"
            
            log_message "BLOCK" "Long-term planning document detected: $file"
            show_constitution_guidance "長期計画作成" "$details"
            return 1
        fi
        
        # 既存ファイルの内容検査（MultiEditの場合）
        if [[ -f "$file" ]] && [[ "$file" =~ \.md$ ]]; then
            # 将来年度の検出
            if grep -q "$FUTURE_YEAR_THRESHOLD\|$(($FUTURE_YEAR_THRESHOLD + 1))\|$(($FUTURE_YEAR_THRESHOLD + 2))" "$file" 2>/dev/null; then
                local details="将来年度への言及: $file (${FUTURE_YEAR_THRESHOLD}年以降の計画は禁止)"
                
                log_message "BLOCK" "Future year planning detected in: $file"
                show_constitution_guidance "長期計画作成" "$details"
                return 1
            fi
            
            # 長期計画キーワードの検出
            if grep -i -q "roadmap\|enhancement.*plan\|long.*term\|future.*strategy" "$file" 2>/dev/null; then
                local details="長期計画キーワード検出: $file"
                
                log_message "BLOCK" "Long-term planning keywords detected in: $file"
                show_constitution_guidance "長期計画作成" "$details"
                return 1
            fi
        fi
    done
    
    return 0
}

# 過剰詳細化検出
check_excessive_detail() {
    local files=("$@")
    
    for file in "${files[@]}"; do
        if is_exempt_file "$file"; then
            continue
        fi
        
        # マークダウンファイルの行数チェック
        if [[ "$file" =~ \.md$ ]] && [[ -f "$file" ]]; then
            local line_count=$(wc -l < "$file")
            
            if (( line_count > MAX_DOCUMENT_LINES )); then
                local details="文書行数: ${line_count}行 (推奨制限: ${MAX_DOCUMENT_LINES}行以下)"
                
                log_message "BLOCK" "Excessive document length detected: $file ($line_count lines)"
                show_constitution_guidance "過剰詳細化" "$details"
                return 1
            fi
        fi
    done
    
    return 0
}

# Hook無効化チェック
if [[ "${CLAUDE_HOOKS_DISABLED:-false}" == "true" ]]; then
    log_message "INFO" "Constitution Guard disabled by environment variable"
    exit 0
fi

# メイン処理
main() {
    log_message "INFO" "Constitution Guard activated"
    
    # ツール名の確認
    local tool_name="${CLAUDE_TOOL_NAME:-unknown}"
    
    if [[ "$tool_name" != "Edit" && "$tool_name" != "MultiEdit" ]]; then
        log_message "INFO" "Tool $tool_name not subject to constitution guard"
        exit 0
    fi
    
    # ツール引数の解析
    local tool_args="${CLAUDE_TOOL_ARGS:-{}}"
    local files=()
    
    # file_pathまたはeditsから対象ファイルを抽出
    if [[ "$tool_name" == "Edit" ]]; then
        # JSON解析（jq不要の簡易版）
        local file_path=$(echo "$tool_args" | grep -o '"file_path":"[^"]*"' | cut -d'"' -f4)
        if [[ -n "$file_path" ]]; then
            files=("$file_path")
        fi
    elif [[ "$tool_name" == "MultiEdit" ]]; then
        # JSON解析（jq不要の簡易版）
        local file_path=$(echo "$tool_args" | grep -o '"file_path":"[^"]*"' | cut -d'"' -f4)
        if [[ -n "$file_path" ]]; then
            files=("$file_path")
        fi
    fi
    
    if [[ ${#files[@]} -eq 0 ]]; then
        log_message "WARNING" "No target files found in tool arguments"
        exit 0
    fi
    
    log_message "INFO" "Checking ${#files[@]} files: ${files[*]}"
    
    # 憲法違反チェックを実行
    if ! check_mass_file_creation "${files[@]}"; then
        exit 2
    fi
    
    if ! check_long_term_planning "${files[@]}"; then
        exit 2
    fi
    
    if ! check_excessive_detail "${files[@]}"; then
        exit 2
    fi
    
    log_message "INFO" "Constitution Guard passed for all files"
    exit 0
}

# エラーハンドリング
trap 'log_message "ERROR" "Unexpected error in constitution-guard.sh"; exit 1' ERR

# メイン処理実行
main "$@"