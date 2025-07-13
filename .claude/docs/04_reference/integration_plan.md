# 文書統合計画 - アーカイブ文書の新構造への配置

## 📋 アーカイブ文書分析

### 1. アクションプラン.md (8KB)
**内容**: 具体的なセットアップ手順とチェックリスト
**配置先**: `01_quickstart/`
**理由**: 実装手順が詳細に記載されており、クイックスタートに最適

### 2. AI駆動開発ワークフローの設計と運用指針.md (59KB)
**内容**: Claude Code のフレームワーク、TDD・YAGNI 原則、Hook 設計
**配置先**: 
- `03_operations/` - 日常運用に関する部分
- `04_reference/` - 技術詳細・設計思想

### 3. 構想.md (22KB)
**内容**: 推奨ドキュメント構成、3層モデル、git worktree 設計
**配置先**:
- `02_templates/` - ドキュメント構成テンプレート
- `04_reference/` - 設計思想・アーキテクチャ

### 4. リポジトリ戦略案.md (15KB)
**内容**: Git worktree を使った疑似モノレポ構成
**配置先**: `04_reference/`
**理由**: 技術的な設計指針として保存

### 5. Claude Code 実践ドキュメント再編成計画書.md (7KB)
**内容**: この再編成の計画書
**配置先**: `04_reference/`
**理由**: 歴史的記録として保存

## 🎯 統合戦略

### Phase 1: 基本構造の完成
1. **01_quickstart/** - アクションプランベースの詳細セットアップガイド
2. **02_templates/** - 構想文書からテンプレート抽出
3. **03_operations/** - ワークフロー指針から運用部分抽出
4. **04_reference/** - 残りの技術詳細・設計思想

### Phase 2: 内容の精選と統合
- 重複内容の排除
- 参照関係の整理
- 実用性の高い部分の抽出

## 📁 新しい文書構成案

### 01_quickstart/
- `README.md` - 詳細セットアップガイド
- `environment_setup.md` - 環境構築手順
- `first_project.md` - 初回プロジェクト作成

### 02_templates/
- `README.md` - テンプレート一覧
- `document_structure.md` - 推奨ドキュメント構成
- `command_templates.md` - Claude コマンドテンプレート

### 03_operations/
- `README.md` - 日常運用ガイド
- `tdd_workflow.md` - TDD 実践方法
- `quality_control.md` - Hook による品質管理

### 04_reference/
- `README.md` - リファレンス索引
- `architecture.md` - システム設計思想
- `claude_framework.md` - Claude Code フレームワーク詳細
- `repository_strategy.md` - リポジトリ戦略
- `integration_plan.md` - この統合計画書

## ✅ 実装チェックリスト

- [ ] 01_quickstart/ へのアクションプラン統合
- [ ] 02_templates/ への構想文書統合
- [ ] 03_operations/ へのワークフロー指針統合
- [ ] 04_reference/ への技術詳細統合
- [ ] 相互参照リンクの整備
- [ ] 重複内容の排除
- [ ] 最終検証