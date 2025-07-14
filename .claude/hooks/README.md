# Claude Code Hooks

> **目的**: TDD × YAGNI × 自動ガードによる品質管理の自動化

## 🎯 概要

Claude Code Hooksは、AIエージェントの動作を監視・制御し、プロジェクトの品質基準を自動的に維持するシステムです。決定論的なルールベースのチェックにより、Claude Codeが生成するコードの品質を保証します。

## 📁 ディレクトリ構造

```
hooks/
├── README.md                    # 本ファイル
├── pre-tool/                    # ツール実行前のフック
│   ├── tdd-guard.sh            # TDD違反検出・ブロック
│   └── constitution-guard.sh   # AI完璧主義防止・憲法遵守
├── post-tool/                   # ツール実行後のフック
│   └── unused-detector.sh      # 未使用コード検出
├── stop/                        # 対話終了前のフック
│   └── coverage-check.sh        # カバレッジ・品質チェック
└── notification/                # 通知・フィードバック
    └── sound-notifier.sh        # 音声通知システム
```

## 🔧 フックの詳細

### PreToolUse: TDD Guard
**ファイル**: `pre-tool/tdd-guard.sh`
**目的**: テスト駆動開発の順序を強制

### PreToolUse: Constitution Guard
**ファイル**: `pre-tool/constitution-guard.sh`
**目的**: AI完璧主義防止・憲法遵守の監視

#### 動作
- プロジェクト憲法（CLAUDE.md）の遵守状況を監視
- 95%以上の完璧主義を検出・防止
- 推測実装・過度な汎用化の抑制
- 大量ドキュメント作成の制限

#### TDD Guard 動作
- 実装ファイルの編集前に、対応するテストファイルの変更を確認
- テスト変更がない場合、実装変更をブロック（exit code 2）
- VBAファイルや設定ファイルは除外

#### ブロック条件
```bash
# ブロックされる例
Edit: src/core/analyzer.py  # テスト変更なし → ❌ ブロック

# 許可される例  
Edit: tests/test_analyzer.py  # テストファイル → ✅ 許可
Edit: src/core/analyzer.py    # 最近テスト変更あり → ✅ 許可
```

### PostToolUse: Unused Code Detector  
**ファイル**: `post-tool/unused-detector.sh`
**目的**: YAGNI原則の遵守を監視

#### 動作
- コード編集後に未使用関数・変数を検出
- Python: vulture または基本的な解析
- JavaScript/TypeScript: ESLint (no-unused-vars)
- 未使用コードがある場合、修正を要求（exit code 2）

#### 検出例
```python
# 未使用関数が検出される例
def helper_function():  # どこからも呼ばれていない
    return "unused"

def main():
    print("Hello")
```

### Stop: Coverage Check
**ファイル**: `stop/coverage-check.sh`  
**目的**: 完了前の品質保証

#### 動作
- Claude Codeが対話終了前に品質基準をチェック
- プロジェクト別の要求事項を確認
- 基準未達の場合、継続作業を強制（exit code 2）

#### プロジェクト別基準
```yaml
danbooru_advanced_wildcard:
  - テストカバレッジ: 80%以上
  - 実装変更時の対応テスト必須

pdi:
  - VBA構造の完全性確認
  - 主要モジュールの存在確認

workspace:
  - 必須設定ファイルの存在確認
  - ガバナンス文書の整合性
```

## ⚙️ 設定

### settings.json との連携
```json
{
  "hooks": {
    "pre_edit": ".claude/hooks/pre-tool/tdd-guard.sh",
    "post_edit": ".claude/hooks/post-tool/unused-detector.sh", 
    "pre_bash": null,
    "post_bash": ".claude/hooks/post-tool/unused-detector.sh",
    "stop": ".claude/hooks/stop/coverage-check.sh"
  }
}
```

### Notification: Sound Notifier
**ファイル**: `notification/sound-notifier.sh`
**目的**: Hook実行時の音声通知

#### 動作
- Hook実行時に音声フィードバックを提供
- 成功・警告・エラー別の音声パターン
- 開発者への即座な状況通知

### 環境変数
フックスクリプトは以下のClaude Code環境変数を使用：
- `CLAUDE_TOOL_NAME`: 実行されたツール名
- `CLAUDE_TOOL_ARGS`: ツールの引数（JSON形式）
- `CLAUDE_TOOL_RESULT`: ツールの実行結果

### ログ出力
すべてのフックは `/tmp/claude-hooks.log` にログを出力：
```bash
# ログ確認
tail -f /tmp/claude-hooks.log

# 特定フックのログのみ表示
grep "tdd-guard" /tmp/claude-hooks.log
```

## 🚀 実践的な使用例

### 典型的なTDD フロー
```bash
# 1. テストファイルを編集 → ✅ 許可
Claude: Edit tests/test_new_feature.py

# 2. テスト実行 → ✅ 許可  
Claude: Bash pytest tests/test_new_feature.py

# 3. 実装ファイル編集 → ✅ 許可（テスト変更あり）
Claude: Edit src/new_feature.py

# 4. 再度実装編集 → ❌ ブロック（新たなテスト変更なし）
Claude: Edit src/new_feature.py
Hook: "TDD Guard: テストコードの変更なしに実装ファイルを変更することはできません"
```

### 未使用コード検出フロー
```bash
# コード編集後、自動で未使用コードをチェック
Claude: Edit src/utils.py
Hook: "未使用コードが検出されました: unused_helper_function"
Claude: "不要な関数を削除します"
Claude: Edit src/utils.py  # 未使用関数を削除
Hook: "✅ 未使用コードなし"
```

### カバレッジチェックフロー  
```bash
# Claude完了前の自動チェック
Claude: "実装が完了しました"
Hook: "カバレッジチェック: 78% < 80% 基準未達"
Claude: "追加のテストケースを実装します"
Claude: Edit tests/test_edge_cases.py
Hook: "カバレッジチェック: 85% ✅ 基準達成"
Claude: "完了しました"
```

## 🔧 トラブルシューティング

### フックが動作しない
```bash
# 実行権限の確認
ls -la .claude/hooks/*/*.sh

# 実行権限がない場合
chmod +x .claude/hooks/*/*.sh
```

### 誤検出の回避
```bash
# テストファイルの例外設定確認
grep -A 10 "is_test_exempt" .claude/hooks/pre-tool/tdd-guard.sh

# 一時的な無効化（緊急時のみ）
export CLAUDE_HOOKS_DISABLED=true
```

### ログでのデバッグ
```bash
# 詳細ログの確認
tail -100 /tmp/claude-hooks.log | grep -A 5 -B 5 "ERROR"

# フック実行の追跡
grep "Hook activated\|exit" /tmp/claude-hooks.log
```

## 🎨 カスタマイズ

### プロジェクト固有のフック
```bash
# プロジェクト固有フックディレクトリ
mkdir -p projects/my_project/.claude/hooks_local/

# 継承 + 拡張パターン
cp .claude/hooks/pre-tool/tdd-guard.sh projects/my_project/.claude/hooks_local/
# → プロジェクト固有のルールを追加
```

### 閾値の調整
```bash
# coverage-check.sh の閾値変更
sed -i 's/MIN_COVERAGE_THRESHOLD=80/MIN_COVERAGE_THRESHOLD=70/' \
  .claude/hooks/stop/coverage-check.sh
```

## 📋 ベストプラクティス

### 1. フックの順守
- **フックメッセージを無視しない**: 品質保証の要
- **段階的な修正**: 一度に多くを変更せず、フックの指示に従う

### 2. プロジェクト固有設定
- **言語特性の考慮**: Python/VBA/JavaScript別の調整
- **チーム合意**: フックルールはチーム全体で合意

### 3. 定期メンテナンス
- **月次レビュー**: フック動作の検証
- **閾値調整**: プロジェクト成熟度に応じた基準変更

---

これらのフックにより、Claude Codeを使った開発でも確実にTDD・YAGNI原則を維持し、高品質なコードベースを保つことができます。

*最終更新: 2025-07-14*