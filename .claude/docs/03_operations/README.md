# 🔄 日常運用ガイド

> **目的**: Claude Code を使った AI 駆動開発の日常運用における実践的なガイドライン

## 📋 運用ガイド一覧

### 基本運用
- **[TDD ワークフロー](tdd_workflow.md)** - テスト駆動開発の実践方法
- **[品質管理](quality_control.md)** - Hook による自動品質管理
- **[実装検証SOP](implementation_verification_sop.md)** - 実装完了の体系的検証手順
- **[Hook統合チェックリスト](hook_integration_checklist.md)** - Hook システム統合手順

### 継続改善
- **[改善推奨事項追跡](improvement_recommendations.md)** - 検証報告から特定された改善事項の管理
- **[文書複雑性監視](document_complexity_monitoring.md)** - 文書品質の継続的監視

### 高度な運用
- **[AI完璧主義監視](ai_perfectionism_monitoring.md)** - AI完璧主義防止システム運用
- **[CLAUDE.md最適化SOP](claude_md_optimization_sop.md)** - プロジェクト憲法の最適化

### 実装状況
- ✅ **完了済み**: tdd_workflow.md, quality_control.md, implementation_verification_sop.md
- ✅ **完了済み**: improvement_recommendations.md, document_complexity_monitoring.md
- ✅ **完了済み**: hook_integration_checklist.md, ai_perfectionism_monitoring.md
- ✅ **完了済み**: claude_md_optimization_sop.md  
- ❌ **未実装**: issue_driven_development.md, parallel_development.md, review_workflow.md
- ❌ **未実装**: troubleshooting.md

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

## 📋 実装優先度

### Phase 1: 基本運用完備（優先度: 高）
1. **issue_driven_development.md** - GitHub Issue を中心とした開発フロー
2. **troubleshooting.md** - よくある問題と解決策

### Phase 2: 高度な運用（優先度: 中）  
1. **parallel_development.md** - 複数タスクの同時進行
2. **review_workflow.md** - 人間-AI 協働レビュー

### Phase 3: 継続改善（優先度: 低）
- 既存運用ガイドの拡張・改善
- 新しい運用パターンの追加

## 🔗 関連ドキュメント

- **[クイックスタート](../01_quickstart/)** - 環境セットアップ手順
- **[テンプレート](../02_templates/)** - 再利用可能なパターン集
- **[リファレンス](../04_reference/)** - 技術詳細・設計思想

---

**次のステップ**: 実装済みの運用ガイドを参照して、具体的な作業フローを確立してください。

*最終更新: 2025-07-14*