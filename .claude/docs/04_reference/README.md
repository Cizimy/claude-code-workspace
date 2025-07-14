# 📚 技術リファレンス

> **目的**: Claude Code システムの技術詳細・設計思想・アーキテクチャ情報

## 📋 リファレンス一覧

### コアシステム
- **[Claude フレームワーク](claude_framework.md)** - Claude Code の動作原理とライフサイクル
- **[統合品質ゲートシステム](integrated_quality_gate_system.md)** - 品質管理の統合システム
- **[憲法ガードシステム](constitution-guard-system.md)** - AI完璧主義防止システム

### 設計指針
- **[文書複雑性制御システム](document-complexity-control-system.md)** - 複雑性抑制の具体的手法
- **[統合計画](integration_plan.md)** - 文書統合・アーカイブ管理
- **[リポジトリ戦略](repository_strategy.md)** - Git worktree による疑似モノレポ

### 実装状況
- ✅ **完了済み**: claude_framework.md, integrated_quality_gate_system.md, constitution-guard-system.md
- ✅ **完了済み**: document-complexity-control-system.md, integration_plan.md, repository_strategy.md  
- ❌ **未実装**: architecture.md, hook_system.md, tdd_principles.md, yagni_implementation.md
- ❌ **未実装**: quality_assurance.md, extension_guide.md

## 🏗️ システムアーキテクチャ概要

### 3層モデル構成
```
┌─────────────────────────────────────────┐
│            Workspace Layer              │
│  (共通設定・横断ツール・ガバナンス)        │
├─────────────────────────────────────────┤
│           Governance Layer              │
│     (意思決定記録・ADR・議事録)           │
├─────────────────────────────────────────┤
│            Project Layer                │
│    (個別実装・プロジェクト固有設定)        │
└─────────────────────────────────────────┘
```

### Claude Code フレームワーク
```
Context → Tools → Permission → Execution → Feedback
   ↑                                          ↓
   └────────── Continuous Loop ←──────────────┘
```

## 🔧 技術スタック

### Core Technologies
- **Claude Code**: AI エージェント実行環境
- **GitHub Actions**: CI/CD・自動化プラットフォーム
- **Git Worktree**: 疑似モノレポ構成
- **Hook System**: 決定論的品質制御

### Quality Tools
- **pytest/jest**: テストフレームワーク
- **coverage**: テストカバレッジ測定
- **vulture**: 未使用コード検出
- **radon**: 複雑度測定
- **trufflehog**: シークレットスキャン

### Development Tools
- **VS Code**: 開発環境 (Dev Container 対応)
- **Docker**: コンテナ化・環境統一
- **ADR Tools**: アーキテクチャ決定記録
- **MkDocs**: ドキュメント生成

## 📊 設計原則

### AI駆動開発の3原則
1. **Test-Driven Development (TDD)**
   - 実装前のテスト作成を強制
   - Red-Green-Refactor サイクルの自動化
   - Hook による TDD 違反の検出・ブロック

2. **YAGNI (You Aren't Gonna Need It)**
   - 現在必要な機能のみ実装
   - 推測実装・過度な汎用化の禁止
   - 未使用コードの自動検出・削除

3. **Automated Quality Gates**
   - Hook による決定論的品質制御
   - 品質基準未達時の自動ブロック
   - 継続的品質改善のフィードバック

### 複雑性抑制戦略
- **小さなPR粒度** - 1 Issue = 1 PR
- **頻繁なコミット** - 変更の粒度を細かく保持
- **関心の分離** - UI・ロジック・データの明確な分離
- **依存関係最小化** - モジュール間結合の最小化

## 🔍 品質メトリクス

### 基準値
| メトリクス | 基準値 | 測定方法 |
|-----------|-------|----------|
| テストカバレッジ | 90%以上 | coverage report |
| 循環的複雑度 | 10以下 | radon cc |
| 未使用コード | 0個 | vulture |
| PR サイズ | 500行以下 | git diff --stat |

### 監視項目
- **Hook 実行統計** - ブロック・警告の発生頻度
- **開発速度** - Issue→PR作成までの時間
- **品質トレンド** - 週次・月次の品質指標推移
- **AI 協働効率** - 人間・Claude の作業分担効率

## 🔗 外部リンク・参考資料

### Claude Code 公式
- [Claude Code Documentation](https://docs.anthropic.com/claude/docs/claude-code)
- [GitHub Actions Integration](https://github.com/anthropics/claude-code-action)
- [Best Practices Guide](https://docs.anthropic.com/claude/docs/claude-code-best-practices)

### 設計思想・手法
- [Test-Driven Development](https://martinfowler.com/bliki/TestDrivenDevelopment.html)
- [YAGNI Principle](https://martinfowler.com/bliki/Yagni.html)
- [ADR (Architecture Decision Records)](https://adr.github.io/)
- [Git Worktree Guide](https://git-scm.com/docs/git-worktree)

### 品質管理
- [Continuous Integration Best Practices](https://martinfowler.com/articles/continuousIntegration.html)
- [Code Quality Metrics](https://en.wikipedia.org/wiki/Software_metric)
- [Security by Design](https://owasp.org/www-project-secure-coding-practices-quick-reference-guide/)

## 🛠️ 実装ガイド

### 新規プロジェクトの追加
1. **Workspace 設定継承** - 基本設定の継承
2. **プロジェクト固有Hook** - 必要に応じてカスタマイズ
3. **CI統合** - 既存CIとの衝突回避
4. **品質基準適用** - プロジェクト特性に応じた調整

### Hook 開発・追加
1. **要件定義** - 検出したい品質問題の明確化
2. **実装** - シェルスクリプトでの Hook 実装
3. **テスト** - 様々なシナリオでの動作確認
4. **段階的導入** - 警告→エラーの段階的強化

### システム拡張
1. **新しい品質メトリクス** - 追加の測定項目
2. **外部ツール統合** - 新しい分析ツールの組み込み
3. **レポート生成** - メトリクスの可視化・ダッシュボード
4. **通知システム** - Slack・メール等への品質アラート

---

## 📋 実装ロードマップ

### Phase 1: 基盤強化（優先度: 高）
1. **architecture.md** - システム全体の設計思想と構成
2. **hook_system.md** - Hook の技術仕様と実装詳細
3. **quality_assurance.md** - 自動品質管理の設計

### Phase 2: 開発支援（優先度: 中）
1. **tdd_principles.md** - テスト駆動開発の理論と実装
2. **yagni_implementation.md** - YAGNI原則の実践方法
3. **extension_guide.md** - システム拡張・カスタマイズ方法

### Phase 3: 継続改善（優先度: 低）
- 既存文書の更新・拡張
- 新しい技術要素の追加
- 外部ツール統合ガイド

---

**活用方法**: 実装済みの技術詳細は個別のリファレンス文書を参照してください。システム拡張・カスタマイズ時は設計原則を遵守し、既存の品質基準を維持してください。

*最終更新: 2025-07-14*