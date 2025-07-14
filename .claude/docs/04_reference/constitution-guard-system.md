# Constitution Guard System 技術仕様書

> **目的**: AI完璧主義症候群防止のための教育的ブロックシステムの技術仕様

## 📋 システム概要

### 目標
Claude Code セッション中のAI完璧主義症候群（大量ドキュメント作成、推測実装、過剰詳細化）を事前検出し、教育的指導によって防止する。

### アプローチ
- **事前検出**: ツール実行前の違反パターン検出
- **教育的ブロック**: 具体的な改善指示を含む建設的な中断
- **憲法強化**: CLAUDE.md への意識的回帰促進

## 🏗️ アーキテクチャ設計

### システム構成図
```
Claude Tool Request
        ↓
    constitution-guard.sh (PreToolUse Hook)
        ↓
    Pattern Detection
    ├── Bulk Document Creation
    ├── Future Planning Detection  
    └── Excessive Detail Detection
        ↓
    Educational Block (if violation)
        ↓
    Exit 2 (Block execution)
```

### 既存Hookとの統合
```
TDD Guard → Constitution Guard → Tool Execution → Unused Detector → Coverage Check
    ↑                                                                    ↓
    └─────────────── Educational Feedback Loop ←──────────────────────────┘
```

## 🔧 核心実装: constitution-guard.sh

### 基本構造
```bash
#!/bin/bash
# Constitution Guard Hook - PreToolUse
# Purpose: Prevent AI perfectionism syndrome through educational blocking

set -euo pipefail

readonly SCRIPT_NAME="constitution-guard.sh"
readonly LOG_FILE="/tmp/claude-hooks.log"
readonly WORKSPACE_ROOT="/home/kenic/projects"

# Hook情報の取得
readonly TOOL_NAME="${CLAUDE_TOOL_NAME:-unknown}"
readonly TOOL_ARGS="${CLAUDE_TOOL_ARGS:-}"

# メイン検出ロジック
main() {
    log_message "Constitution Guard activated: tool=$TOOL_NAME"
    
    # 対象ツールのフィルタリング
    if [[ "$TOOL_NAME" != "Write" && "$TOOL_NAME" != "Edit" && "$TOOL_NAME" != "MultiEdit" ]]; then
        exit 0
    fi
    
    # 違反パターン検出
    detect_constitution_violation
}
```

### 違反パターン検出

#### 1. 大量ドキュメント作成検出
```bash
detect_bulk_document_creation() {
    local file_count=0
    local violation_type=""
    
    if [[ "$TOOL_NAME" == "MultiEdit" ]]; then
        # JSON args からファイル数を抽出
        file_count=$(echo "$TOOL_ARGS" | grep -c "file_path" || echo "0")
        
        if [[ $file_count -gt 4 ]]; then
            violation_type="bulk_document_creation"
            trigger_educational_block "$violation_type" "$file_count"
        fi
    fi
}
```

#### 2. 長期計画文書検出
```bash
detect_future_planning() {
    local file_path=$(extract_file_path "$TOOL_ARGS")
    
    if [[ -n "$file_path" ]]; then
        # ファイル内容の事前チェック（Write/Editの場合）
        local content=""
        if [[ "$TOOL_NAME" == "Write" ]]; then
            content=$(echo "$TOOL_ARGS" | jq -r '.content // empty' 2>/dev/null || echo "")
        elif [[ "$TOOL_NAME" == "Edit" && -f "$file_path" ]]; then
            content=$(cat "$file_path" 2>/dev/null || echo "")
        fi
        
        # 長期計画キーワード検出
        if echo "$content" | grep -q -i "202[6-9]\|roadmap.*202[6-9]\|enhancement.*202[6-9]\|2027\|2028"; then
            trigger_educational_block "future_planning" "$file_path"
        fi
    fi
}
```

#### 3. 過剰詳細化検出
```bash
detect_excessive_detail() {
    local file_path=$(extract_file_path "$TOOL_ARGS")
    
    if [[ -n "$file_path" ]]; then
        local line_count=0
        
        if [[ "$TOOL_NAME" == "Write" ]]; then
            # 新規作成時の行数チェック
            line_count=$(echo "$TOOL_ARGS" | jq -r '.content // empty' | wc -l)
        elif [[ -f "$file_path" ]]; then
            # 既存ファイルの行数チェック
            line_count=$(wc -l < "$file_path")
        fi
        
        if [[ $line_count -gt 500 ]]; then
            trigger_educational_block "excessive_detail" "$file_path:$line_count"
        fi
    fi
}
```

### 教育的ブロックメッセージ

#### メッセージ設計原則
- **具体的指摘**: 何が問題かを明確に示す
- **憲法引用**: CLAUDE.md の該当原則を引用
- **建設的解決策**: 次に取るべきアクション
- **自己チェック**: 考え直すための質問

#### 実装例
```bash
trigger_educational_block() {
    local violation_type="$1"
    local context="$2"
    
    case "$violation_type" in
        "bulk_document_creation")
            cat >&2 << EOF
🚫 プロジェクト憲法違反が検出されました

【違反内容】
大量ドキュメント作成（${context}ファイル同時作成）

【憲法原則】
CLAUDE.md: "NEVER proactively create documentation files"
CLAUDE.md: "Keep it simple"
CLAUDE.md: "Implement only what's needed now"

【是正指示】
1. CLAUDE.md を再読してください
2. 本当に必要な1ファイルのみに絞り込んでください
3. YAGNI原則（You Aren't Gonna Need It）を思い出してください

【自己チェック質問】
• この作業は今すぐ必要ですか？
• 実証された価値がありますか？
• 95%の完成度で十分ではありませんか？
EOF
            ;;
        "future_planning")
            cat >&2 << EOF
🚫 YAGNI原則違反：将来推測実装が検出されました

【違反内容】
長期計画・推測的実装（2026年以降の計画等）
対象: ${context}

【憲法原則】
CLAUDE.md: "Implement only what's needed now"
CLAUDE.md: "No speculative features"

【是正指示】
1. 今すぐ必要な機能のみに絞り込んでください
2. 将来の「かもしれない」は実装しないでください
3. 必要になった時点で実装してください
EOF
            ;;
        "excessive_detail")
            cat >&2 << EOF
🚫 過剰詳細化が検出されました

【違反内容】
大量ドキュメント作成（${context}行）

【憲法原則】
CLAUDE.md: "Keep it simple"
プロジェクトポリシー: 最小限のドキュメント

【是正指示】
1. 本当に必要な情報のみに絞ってください
2. 複雑な説明を避け、シンプルに保ってください  
3. 分割可能な場合は小さく分けてください
EOF
            ;;
    esac
    
    echo "" >&2
    echo "🛑 作業を一時停止し、憲法原則を確認してから再開してください" >&2
    log_message "CONSTITUTION VIOLATION: $violation_type - $context"
    exit 2
}
```

## 🔄 既存Hookとの統合

### Hook実行順序
1. **tdd-guard.sh** (TDD違反チェック)
2. **constitution-guard.sh** (憲法違反チェック) ← 新規追加
3. **Tool Execution** (実際のツール実行)
4. **unused-detector.sh** (未使用コード検出)
5. **coverage-check.sh** (カバレッジチェック)

### settings.json設定
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|MultiEdit|Write",
        "hooks": [
          {"command": ".claude/hooks/pre-tool/tdd-guard.sh"},
          {"command": ".claude/hooks/pre-tool/constitution-guard.sh"}
        ]
      }
    ]
  }
}
```

### 除外対象の統一
```bash
# 共通除外関数（複数Hookで共有）
is_constitution_exempt() {
    local file="$1"
    
    # テストファイルは除外
    [[ "$file" =~ test.*\.(py|js|ts)$ ]] && return 0
    [[ "$file" =~ .*test\.(py|js|ts)$ ]] && return 0
    
    # 設定ファイルは除外
    [[ "$file" =~ \.(json|yml|yaml|toml|ini)$ ]] && return 0
    
    # ガバナンス・Hook・テンプレートは除外
    [[ "$file" =~ (governance|\.claude|templates)/ ]] && return 0
    
    return 1
}
```

## 📊 ログ・監視システム

### ログ形式
```bash
log_violation() {
    local violation_type="$1"
    local context="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # 構造化ログ
    echo "{\"timestamp\":\"$timestamp\",\"type\":\"constitution_violation\",\"violation\":\"$violation_type\",\"context\":\"$context\",\"tool\":\"$TOOL_NAME\"}" >> "/tmp/constitution-violations.jsonl"
}
```

### 統計収集
```bash
# 週次統計生成
generate_violation_stats() {
    local log_file="/tmp/constitution-violations.jsonl"
    
    if [[ -f "$log_file" ]]; then
        echo "Constitution Violation Statistics (Last 7 days):"
        
        # 違反タイプ別集計
        jq -r 'select(.timestamp >= (now - 7*24*3600 | strftime("%Y-%m-%d"))) | .violation' "$log_file" | sort | uniq -c | sort -nr
        
        # 日別トレンド
        jq -r 'select(.timestamp >= (now - 7*24*3600 | strftime("%Y-%m-%d"))) | .timestamp[:10]' "$log_file" | sort | uniq -c
    fi
}
```

## 🎯 パフォーマンス考慮

### 効率化戦略
1. **早期リターン**: 対象外ツール・ファイルの即座除外
2. **軽量検出**: 正規表現による高速パターンマッチング
3. **キャッシュ活用**: ファイル内容の重複読み込み回避

### 実装例
```bash
# 効率的なファイル内容取得
get_file_content_cached() {
    local file="$1"
    local cache_key="content_$(echo "$file" | md5sum | cut -d' ' -f1)"
    local cache_file="/tmp/$cache_key"
    
    # キャッシュチェック（5分間有効）
    if [[ -f "$cache_file" && $(($(date +%s) - $(stat -c %Y "$cache_file"))) -lt 300 ]]; then
        cat "$cache_file"
    else
        # ファイル読み込み＆キャッシュ保存
        if [[ -f "$file" ]]; then
            cat "$file" | tee "$cache_file"
        fi
    fi
}
```

## 🔧 設定・カスタマイズ

### 閾値設定
```bash
# 設定可能パラメータ
readonly MAX_FILES_BULK=4           # 大量作成判定ファイル数
readonly MAX_LINES_DETAIL=500       # 過剰詳細判定行数
readonly FUTURE_YEAR_THRESHOLD=2026 # 長期計画判定年

# 環境変数での上書き対応
MAX_FILES_BULK=${CONSTITUTION_MAX_FILES:-$MAX_FILES_BULK}
MAX_LINES_DETAIL=${CONSTITUTION_MAX_LINES:-$MAX_LINES_DETAIL}
```

### プロジェクト固有設定
```bash
# プロジェクト別設定読み込み
load_project_config() {
    local project_root="$1"
    local config_file="$project_root/.claude/constitution.conf"
    
    if [[ -f "$config_file" ]]; then
        source "$config_file"
        log_message "Loaded project-specific constitution config"
    fi
}
```

## 🚀 デプロイ・運用

### インストール手順
```bash
# 1. ファイル配置
cp constitution-guard.sh .claude/hooks/pre-tool/
chmod +x .claude/hooks/pre-tool/constitution-guard.sh

# 2. Hook設定更新
# .claude/settings.json に PreToolUse Hook追加

# 3. 動作確認
echo '{"file_path": "test1.md"}' | CLAUDE_TOOL_NAME="Write" CLAUDE_TOOL_ARGS='{"content":"'$(printf '%*s' 600 '' | tr ' ' 'x')'"}' .claude/hooks/pre-tool/constitution-guard.sh
```

### 緊急無効化
```bash
# 一時無効化
export CLAUDE_HOOKS_DISABLED=true

# 恒久無効化
mv .claude/hooks/pre-tool/constitution-guard.sh .claude/hooks/pre-tool/constitution-guard.sh.disabled
```

## 📈 今後の拡張

### 機械学習統合
- 違反パターンの自動学習
- 検出精度の継続的改善
- 個人別カスタマイズ

### 通知システム
- Slack 統合による違反通知
- ダッシュボードでの統計可視化
- 週次/月次レポート自動生成

### 多言語対応
- 英語・日本語メッセージの言語切り替え
- 国際プロジェクト対応

---

*この技術仕様書は、AI完璧主義症候群の技術的防止策として、実装・運用・保守に必要な全ての技術詳細を提供します。*