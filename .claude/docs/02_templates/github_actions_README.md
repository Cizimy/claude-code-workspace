# 🔄 GitHub Actions テンプレート

> **目的**: Claude Code連携のためのCI/CDパイプラインテンプレート

## 📋 利用可能なテンプレート

### 🤖 github_actions_claude.yml
**用途**: Claude Code との完全統合ワークフロー

#### 主な機能
- **@claude メンション検出**: Issue/PRコメントでの自動起動
- **TDD品質ゲート**: テスト駆動開発の自動チェック
- **カバレッジ監視**: 最小カバレッジ閾値の維持
- **YAGNI準拠検証**: 未使用コードの自動検出
- **並行実行制御**: 複数Claudeインスタンスの衝突防止

## 🚀 セットアップ手順

### 1. ワークフローファイルの配置
```bash
# テンプレートをコピー
mkdir -p .github/workflows
cp .claude/docs/02_templates/github_actions_claude.yml .github/workflows/claude.yml
```

### 2. プレースホルダーの置換
```bash
# 基本情報の設定
sed -i 's/\[PROJECT_NAME\]/MyProject/g' .github/workflows/claude.yml
sed -i 's/\[MIN_COVERAGE\]/80/g' .github/workflows/claude.yml
sed -i 's/\[DEFAULT_BRANCH\]/main/g' .github/workflows/claude.yml

# 言語固有の設定（例：Python）
sed -i 's/\[PROGRAMMING_LANGUAGE\]/Python/g' .github/workflows/claude.yml
sed -i 's/\[SETUP_ACTION\]/python/g' .github/workflows/claude.yml
sed -i 's/\[LANGUAGE_VERSION_KEY\]/python-version/g' .github/workflows/claude.yml
sed -i 's/\[LANGUAGE_VERSION_ENV\]/PYTHON_VERSION/g' .github/workflows/claude.yml
sed -i 's/\[PACKAGE_MANAGER\]/pip/g' .github/workflows/claude.yml
sed -i 's/\[INSTALL_COMMAND\]/pip install -r requirements.txt/g' .github/workflows/claude.yml
sed -i 's/\[TEST_COMMAND\]/pytest/g' .github/workflows/claude.yml
sed -i 's/\[COVERAGE_COMMAND\]/pytest --cov=src --cov-report=term-missing/g' .github/workflows/claude.yml
sed -i 's/\[LINT_COMMAND\]/ruff check/g' .github/workflows/claude.yml
```

### 3. Secrets の設定
GitHub リポジトリの Settings → Secrets and variables → Actions で以下を追加：

```yaml
Required Secrets:
  CLAUDE_API_KEY: "Claude Code API キー"
  GITHUB_TOKEN: "自動生成（通常設定不要）"

Optional Secrets:
  SLACK_WEBHOOK: "品質レポート通知用（オプション）"
  DISCORD_WEBHOOK: "チーム通知用（オプション）"
```

## 🎯 使用方法

### 自動トリガー
1. **Issueベース起動**
   ```markdown
   @claude この機能を実装してください
   ```

2. **ラベルベース起動**
   - `feature` ラベル → `/project:new-feature` 実行
   - `bug` ラベル → `/project:fix-bug` 実行
   - `claude`, `ai-dev`, `tdd` ラベル → 自動解析

3. **PRベース品質ゲート**
   - PR作成/更新時に自動実行
   - TDD準拠・カバレッジ・YAGNI準拠をチェック
   - 結果をPRコメントで報告

### 手動トリガー
```bash
# GitHub CLI での手動実行
gh workflow run claude.yml \
  --field issue_number=123 \
  --field command=new-feature
```

## 🔧 言語別カスタマイズ

### Python プロジェクト
```yaml
env:
  PYTHON_VERSION: "3.9"
  
# setup-python@v4 を使用
# pytest + ruff + coverage の標準設定
```

### Node.js プロジェクト
```yaml
env:
  NODE_VERSION: "18"
  
# setup-node@v4 を使用  
# Jest + ESLint + nyc の標準設定
```

### VBA プロジェクト
```yaml
# 特別な環境設定は不要
# 手動テスト + 構造チェックのみ
# カバレッジ要求を緩和（70%等）
```

## 📊 品質ゲート詳細

### TDD準拠チェック
```yaml
✅ 検証項目:
  - テストディレクトリの存在
  - 変更されたコードに対応するテスト変更
  - Red→Green→Refactorサイクルの完了
  
❌ 失敗条件:
  - テストなしでの実装変更
  - テストディレクトリの欠如
  - テスト実行の失敗
```

### カバレッジゲート
```yaml
✅ 合格基準:
  - 全体カバレッジが最小閾値以上
  - 新規コードは100%カバー
  - カバレッジ低下がない
  
📊 レポート内容:
  - ライン別カバレッジ
  - ブランチカバレッジ  
  - 未カバー部分の詳細
```

### YAGNI準拠チェック
```yaml
🔍 検出対象:
  - 未使用関数・クラス・変数
  - 呼び出されていないメソッド
  - 不要なインポート
  
⚠️ 警告レベル:
  - 軽微: 未使用インポート
  - 重要: 未使用パブリック関数
  - 致命的: 大きな未使用クラス
```

## 🎨 高度なカスタマイズ

### プロジェクト固有の品質ルール
```yaml
# カスタムチェックステップを追加
- name: Custom Quality Checks
  run: |
    # プロジェクト固有のルール
    # - API契約の検証
    # - セキュリティスキャン
    # - パフォーマンステスト
    ./scripts/custom-quality-check.sh
```

### 通知の設定
```yaml
# Slack通知の例
- name: Notify Success
  if: success()
  env:
    SLACK_WEBHOOK: ${{ secrets.SLACK_WEBHOOK }}
  run: |
    curl -X POST -H 'Content-type: application/json' \
      --data '{"text":"✅ Claude Code実行成功: ${{ github.event.issue.title }}"}' \
      $SLACK_WEBHOOK
```

### 並行実行の制御
```yaml
# 高度な並行制御
concurrency:
  group: claude-${{ github.repository }}-${{ github.event.issue.number }}
  cancel-in-progress: false  # Claudeの作業を中断させない
```

## 🚨 トラブルシューティング

### よくある問題

| 症状 | 原因 | 解決策 |
|------|------|--------|
| Claude API呼び出し失敗 | API Key未設定 | Secretsに CLAUDE_API_KEY を追加 |
| テスト実行エラー | 依存関係不足 | requirements.txt/package.json を確認 |
| 権限エラー | Token権限不足 | GitHub Token の権限を確認 |
| 並行実行エラー | 同時実行制限 | concurrency設定を調整 |

### デバッグ方法
```bash
# GitHub Actions ログの確認
gh run list --workflow=claude.yml
gh run view [RUN_ID] --log

# ローカルでのワークフローテスト
act -j claude-issue-handler  # act ツールを使用
```

## 🔄 継続的改善

### メトリクス収集
- **実行回数**: Claude Code起動頻度
- **成功率**: 品質ゲート通過率
- **平均実行時間**: パフォーマンス監視
- **品質向上**: バグ減少・カバレッジ向上

### 定期レビュー
- **月次**: ワークフロー効率性の確認
- **四半期**: 品質基準の見直し
- **年次**: 全体的なCI/CD戦略の評価

## 📋 チェックリスト

### 初期セットアップ
- [ ] テンプレートファイルのコピー
- [ ] プレースホルダーの置換完了
- [ ] Secrets設定完了
- [ ] 初回実行テスト成功
- [ ] 品質ゲートの動作確認

### 運用開始後
- [ ] チームメンバーへの使用方法共有
- [ ] Issue/PRテンプレートの更新
- [ ] 品質基準の合意形成
- [ ] エスカレーション手順の確立

## 🔗 関連ドキュメント

- **[Claude Code Commands](../commands/)** - ワークフローで使用されるコマンド
- **[Hooks](../hooks/)** - ローカル品質ガードとの連携
- **[Governance](../governance/)** - CI/CD変更の意思決定記録

---

このテンプレートにより、Claude Code を使った開発フローを GitHub Actions で完全に自動化し、品質を保ちながら効率的な開発を実現できます。

*最終更新: 2025-07-10*