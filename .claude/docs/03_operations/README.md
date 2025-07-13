# 🔄 日常運用ガイド

> **目的**: Claude Code を使った AI 駆動開発の日常運用における実践的なガイドライン

## 📋 運用ガイド一覧

### 基本運用
- **[TDD ワークフロー](tdd_workflow.md)** - テスト駆動開発の実践方法
- **[品質管理](quality_control.md)** - Hook による自動品質管理
- **[Issue 駆動開発](issue_driven_development.md)** - GitHub Issue を中心とした開発フロー

### 高度な運用
- **[並行開発管理](parallel_development.md)** - 複数タスクの同時進行
- **[レビューワークフロー](review_workflow.md)** - 人間-AI 協働レビュー
- **[トラブルシューティング](troubleshooting.md)** - よくある問題と解決策

## 🎯 基本原則

### AI 駆動開発の3つの柱
1. **TDD (テスト駆動開発)** - 実装前にテスト作成を徹底
2. **YAGNI (You Aren't Gonna Need It)** - 必要な機能のみ実装
3. **Hook による自動ガード** - 品質基準の自動監視・制御

### 日常運用のサイクル
```
Issue 作成 → Claude 呼び出し → TDD 実行 → PR 生成 → レビュー → マージ
     ↑                                                        ↓
     └────────────── 継続的改善・フィードバック ←──────────────────┘
```

## ⚡ クイックリファレンス

### よく使うコマンド
| コマンド | 用途 | 例 |
|----------|------|-----|
| `/project:new-feature` | 新機能開発 | `/project:new-feature proj_a#123` |
| `/project:fix-bug` | バグ修正 | `/project:fix-bug proj_a#456` |
| `/workspace:metrics` | 品質メトリクス確認 | `/workspace:metrics` |

### Hook 確認コマンド
```bash
# Hook 実行状況確認
cat .claude/logs/hook-execution.log

# 未使用コード検出
.claude/hooks/post-tool/unused-detector.sh

# カバレッジ確認
.claude/hooks/stop/coverage-check.sh
```

### 品質基準
- **テストカバレッジ**: 新規コード 100%
- **未使用コード**: ゼロ tolerance
- **PR 粒度**: 1 Issue = 1 PR
- **コミット粒度**: 小さく・頻繁に

## 🚨 よくある問題

### Claude が反応しない
1. **原因**: API Key 未設定・期限切れ
2. **確認**: GitHub Secrets の `CLAUDE_API_KEY`
3. **解決**: 新しい API Key を設定

### Hook エラーで進まない  
1. **原因**: 実行権限不足・構文エラー
2. **確認**: `ls -la .claude/hooks/**/*.sh`
3. **解決**: `chmod +x` で実行権限付与

### テストが通らない
1. **原因**: 依存関係・環境設定の問題
2. **確認**: `python -m pytest --version`, `npm test`
3. **解決**: 依存関係の再インストール

## 📈 運用改善のヒント

### 効率化のポイント
1. **Issue テンプレート活用** - 受け入れ基準・テストケースを標準化
2. **Hook の段階的導入** - 厳しすぎる制約は後から緩和
3. **メトリクス定期確認** - 週次でカバレッジ・複雑度をチェック
4. **失敗ログの活用** - Claude の転けポイントを分析・改善

### チーム運用時の注意点
- **並行作業の制限** - 同時 Issue 数を絞って衝突回避
- **ドメイン分離** - プロジェクト・モジュール単位での担当分け  
- **レビュー分担** - AI 出力の最終確認は人間が担当

## 🔗 関連ドキュメント

- **[クイックスタート](../01_quickstart/)** - 環境セットアップ手順
- **[テンプレート](../02_templates/)** - 再利用可能なパターン集
- **[リファレンス](../04_reference/)** - 技術詳細・設計思想

---

**次のステップ**: 各種運用ガイドを参照して、具体的な作業フローを確立してください。