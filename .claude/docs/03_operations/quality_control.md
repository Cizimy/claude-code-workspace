# ⚙️ 品質管理 - Hook による自動制御

> **目的**: Claude Code Hook を使った決定論的な品質管理システムの運用

## 📋 Hook システム概要

### Hook の種類と役割
| Hook Type | 実行タイミング | 用途 | Exit Code 2 の効果 |
|-----------|----------------|------|-------------------|
| **PreToolUse** | ツール実行前 | 事前チェック・実行ブロック | ツール実行をキャンセル |
| **PostToolUse** | ツール実行後 | 結果検証・追加処理 | 警告表示 |
| **Stop** | 応答終了前 | 完了条件チェック | 応答終了をブロック |

### Hook による品質ガード
```
開発フロー     Hook ガード
───────       ──────────
Issue作成
    ↓
Claude起動
    ↓         PreToolUse: 事前チェック
ツール実行  ← ────────────────────────
    ↓         PostToolUse: 結果検証
結果確認   ← ────────────────────────
    ↓         Stop: 完了条件チェック
応答完了   ← ────────────────────────
```

## 🛡️ 主要な Hook 実装

### 1. TDD ガード (PreToolUse)
**目的**: テスト無し実装を防止

```bash
#!/bin/bash
# .claude/hooks/pre-tool/tdd-guard.sh

TOOL_NAME="$1"
TOOL_ARGS="$2"

if [[ "$TOOL_NAME" == "write" ]] && [[ "$TOOL_ARGS" == *".py"* ]]; then
  # ソースコード編集を検出
  
  # 最近のコミットでテスト変更があるかチェック
  recent_test_changes=$(git log --oneline -n 5 --grep="test" --grep="Test" --grep="TEST")
  
  if [[ -z "$recent_test_changes" ]]; then
    echo "🚫 ERROR: テストコードの変更が見つかりません" >&2
    echo "📝 TDD原則に従い、実装前にテストを作成してください" >&2
    echo "💡 例: python -m pytest tests/test_new_feature.py" >&2
    exit 2
  fi
  
  echo "✅ TDD確認: 最近のテスト変更を検出しました" >&2
fi
```

### 2. 未使用コード検出 (PostToolUse)
**目的**: YAGNI 違反の検出・削除促進

```bash
#!/bin/bash
# .claude/hooks/post-tool/unused-detector.sh

TOOL_NAME="$1"

if [[ "$TOOL_NAME" == "write" ]] || [[ "$TOOL_NAME" == "edit" ]]; then
  
  if command -v vulture >/dev/null; then
    # 未使用コード検出
    unused_output=$(vulture . --min-confidence 80 2>/dev/null | grep -v "__pycache__" | grep -v ".git")
    
    if [[ -n "$unused_output" ]]; then
      echo "⚠️  WARNING: 未使用コードが検出されました" >&2
      echo "📋 検出された項目:" >&2
      echo "$unused_output" >&2
      echo "" >&2
      echo "🎯 YAGNI原則に従い、以下のいずれかを実行してください:" >&2
      echo "   1. 不要なコードを削除" >&2
      echo "   2. 該当機能のテストを追加" >&2
      echo "   3. 将来使用予定の場合はコメントで理由を明記" >&2
    else
      echo "✅ 未使用コード検査: 問題なし" >&2
    fi
  else
    echo "⚠️  vulture が見つかりません。未使用コード検査をスキップします" >&2
  fi
fi
```

### 3. カバレッジチェック (Stop)
**目的**: テストカバレッジ不足の完了阻止

```bash
#!/bin/bash
# .claude/hooks/stop/coverage-check.sh

echo "🔍 テストカバレッジを確認中..." >&2

if command -v coverage >/dev/null; then
  # カバレッジ実行
  coverage run -m pytest >/dev/null 2>&1
  
  # カバレッジ率取得
  coverage_report=$(coverage report 2>/dev/null)
  coverage_percent=$(echo "$coverage_report" | tail -1 | grep -o '[0-9]*%' | head -1 | sed 's/%//')
  
  # 未カバー行の確認
  missing_lines=$(coverage report --show-missing 2>/dev/null | grep -v "100%" | wc -l)
  
  if [[ $coverage_percent -lt 90 ]]; then
    echo "🚫 ERROR: テストカバレッジが基準を下回っています" >&2
    echo "📊 現在のカバレッジ: $coverage_percent% (基準: 90%)" >&2
    echo "📋 未カバー箇所:" >&2
    coverage report --show-missing 2>/dev/null | grep -v "100%" >&2
    echo "" >&2
    echo "💡 新規コードのカバレッジを100%にしてから完了してください" >&2
    exit 2
  fi
  
  echo "✅ カバレッジ確認: $coverage_percent% (基準クリア)" >&2
else
  echo "⚠️  coverage が見つかりません。カバレッジ確認をスキップします" >&2
fi
```

## 🔧 高度な Hook 機能

### 4. セキュリティスキャン (PreToolUse)
```bash
#!/bin/bash
# .claude/hooks/pre-tool/secret-scan.sh

TOOL_NAME="$1"
TOOL_ARGS="$2"

if [[ "$TOOL_NAME" == "bash" ]]; then
  # bash コマンド実行前にシークレット検査
  
  if command -v trufflehog >/dev/null; then
    # Git履歴のスキャン
    secrets_found=$(trufflehog git file://. --only-verified 2>/dev/null)
    
    if [[ -n "$secrets_found" ]]; then
      echo "🔒 ERROR: シークレット情報が検出されました" >&2
      echo "$secrets_found" >&2
      echo "⚠️  コミット前にシークレットを削除してください" >&2
      exit 2
    fi
  fi
  
  # 環境変数の漏洩チェック
  if echo "$TOOL_ARGS" | grep -E "(API_KEY|SECRET|PASSWORD|TOKEN)" >/dev/null; then
    echo "🔒 WARNING: コマンドに機密情報らしき文字列が含まれています" >&2
    echo "🔍 確認してください: $TOOL_ARGS" >&2
  fi
fi
```

### 5. 複雑度チェック (PostToolUse)
```bash
#!/bin/bash
# .claude/hooks/post-tool/complexity-check.sh

TOOL_NAME="$1"

if [[ "$TOOL_NAME" == "write" ]] || [[ "$TOOL_NAME" == "edit" ]]; then
  
  if command -v radon >/dev/null; then
    # 循環的複雑度チェック
    complex_files=$(radon cc . -s --min=C 2>/dev/null)
    
    if [[ -n "$complex_files" ]]; then
      echo "📊 WARNING: 高い複雑度のコードが検出されました" >&2
      echo "$complex_files" >&2
      echo "" >&2
      echo "💡 以下の改善を検討してください:" >&2
      echo "   1. 関数の分割 (単一責任原則)" >&2
      echo "   2. 条件分岐の簡素化" >&2
      echo "   3. 早期リターンの活用" >&2
    fi
    
    # メンテナビリティ指数チェック
    maintainability=$(radon mi . --show 2>/dev/null | grep -E "(LOW|VERY LOW)")
    if [[ -n "$maintainability" ]]; then
      echo "🔧 WARNING: 低いメンテナビリティのファイルがあります" >&2
      echo "$maintainability" >&2
    fi
  fi
fi
```

## 📊 品質メトリクス自動収集

### Hook ログの構造化
```bash
#!/bin/bash
# .claude/hooks/utils/log-metrics.sh

log_metrics() {
  local hook_type="$1"
  local tool_name="$2"
  local status="$3"
  local details="$4"
  
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  log_entry=$(cat <<EOF
{
  "timestamp": "$timestamp",
  "hook_type": "$hook_type", 
  "tool_name": "$tool_name",
  "status": "$status",
  "details": "$details",
  "project": "$(basename $PWD)"
}
EOF
)
  
  echo "$log_entry" >> .claude/logs/quality-metrics.jsonl
}

# 使用例
log_metrics "pre-tool" "write" "blocked" "TDD violation detected"
log_metrics "post-tool" "edit" "warning" "unused code found: 3 items"
log_metrics "stop" "coverage" "passed" "coverage: 95%"
```

### メトリクスダッシュボード
```python
#!/usr/bin/env python3
# scripts/quality-dashboard.py

import json
import matplotlib.pyplot as plt
from collections import defaultdict
from datetime import datetime, timedelta

def analyze_quality_metrics():
    """品質メトリクスを分析してダッシュボード生成"""
    
    metrics = []
    with open('.claude/logs/quality-metrics.jsonl', 'r') as f:
        for line in f:
            metrics.append(json.loads(line))
    
    # Hook実行統計
    hook_stats = defaultdict(int)
    for metric in metrics:
        hook_stats[metric['hook_type']] += 1
    
    # 週次の品質トレンド
    weekly_issues = defaultdict(list)
    for metric in metrics:
        week = datetime.fromisoformat(metric['timestamp']).strftime('%Y-W%U')
        if metric['status'] in ['blocked', 'warning']:
            weekly_issues[week].append(metric)
    
    print("📊 品質メトリクス サマリー")
    print("=" * 30)
    print(f"Hook実行回数: {sum(hook_stats.values())}")
    print(f"品質問題検出: {len([m for m in metrics if m['status'] in ['blocked', 'warning']])}")
    print(f"最新カバレッジ: {get_latest_coverage()}%")
    
if __name__ == "__main__":
    analyze_quality_metrics()
```

## 🎛️ Hook 設定管理

### settings.json での Hook 有効化
```json
{
  "hookPaths": [
    "../.claude/hooks"
  ],
  "hooks": {
    "pre-tool": {
      "tdd-guard": true,
      "secret-scan": true
    },
    "post-tool": {
      "unused-detector": true,
      "complexity-check": true
    },
    "stop": {
      "coverage-check": true
    }
  }
}
```

### プロジェクト固有の Hook オーバーライド
```json
// projects/proj_a/.claude/settings.json
{
  "extends": "../../.claude/settings.json",
  "hooks": {
    "stop": {
      "coverage-check": false,  // 一時的に無効化
      "integration-test": true  // プロジェクト固有Hook
    }
  }
}
```

## 🚨 トラブルシューティング

### Hook エラーの対処
```bash
# Hook実行権限確認
find .claude/hooks -name "*.sh" -exec ls -la {} \;

# Hook構文確認
find .claude/hooks -name "*.sh" -exec bash -n {} \;

# Hook実行テスト
.claude/hooks/pre-tool/tdd-guard.sh write src/test.py
```

### デバッグモード
```bash
# Hook デバッグ実行
export CLAUDE_HOOK_DEBUG=1
.claude/hooks/post-tool/unused-detector.sh write

# 詳細ログ出力
bash -x .claude/hooks/stop/coverage-check.sh
```

### Hook の段階的導入
```bash
# 1. 警告のみで開始
sed -i 's/exit 2/exit 0/' .claude/hooks/*/strict-*.sh

# 2. 段階的に厳格化
# WARNING → ERROR に変更
sed -i 's/WARNING/ERROR/' .claude/hooks/post-tool/unused-detector.sh
sed -i 's/exit 0/exit 2/' .claude/hooks/post-tool/unused-detector.sh
```

## 📈 継続的改善

### Hook 効果の測定
- **品質問題の減少率** - 週次での issue 検出数推移
- **開発速度への影響** - PR 作成時間の変化
- **開発者満足度** - Hook による中断頻度と受容度

### Hook ルールの調整
- **False Positive の削減** - 不要な警告の除外ルール追加
- **閾値の最適化** - カバレッジ・複雑度基準の調整
- **新規 Hook の追加** - プロジェクト固有の品質基準

---

**次のステップ**: [Issue 駆動開発](issue_driven_development.md) で GitHub Issue を中心とした開発フローを確認してください。