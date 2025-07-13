# 🧩 Templates（テンプレート集）

> **目的**: コピー&ペーストで即座に使える実用的なテンプレート集

## 📁 利用可能なテンプレート

### 📜 CLAUDE.md.template
**ファイル**: `CLAUDE.md.template`
**用途**: 新しいプロジェクト用のプロジェクト憲法

#### 使用方法
```bash
# 新プロジェクトでの使用
cp .claude/docs/02_templates/CLAUDE.md.template my_project/CLAUDE.md

# プレースホルダーを置換
sed -i 's/\[PROJECT_NAME\]/MyAwesomeProject/g' my_project/CLAUDE.md
sed -i 's/\[PROJECT_DESCRIPTION\]/AI-powered data analysis tool/g' my_project/CLAUDE.md
# 他のプレースホルダーも同様に置換...
```

#### 主なプレースホルダー
- `[PROJECT_NAME]`: プロジェクト名
- `[PROJECT_DESCRIPTION]`: プロジェクトの説明
- `[PROJECT_TYPE]`: プロジェクトタイプ（Python/VBA/JavaScript等）
- `[PROGRAMMING_LANGUAGE]`: 使用言語
- `[TEST_FRAMEWORK]`: テストフレームワーク
- `[MIN_COVERAGE]`: 最小カバレッジ要求（推奨: 80）

## 🎯 テンプレート設計原則

### 1. 即座に使える
- コピー&ペーストで動作する
- 最小限の編集で使用開始
- 具体例とコメント付き

### 2. TDD × YAGNI 準拠
- テスト駆動開発の手順を明記
- YAGNI原則の遵守を強制
- 自動品質ガードとの連携

### 3. プロジェクト憲法
- Claude Codeが最優先で参照
- 人間開発者にも理解しやすい
- 段階的カスタマイズ可能

## 🔧 カスタマイズガイド

### プロジェクト固有の追加
```markdown
## 🎨 [プロジェクト名] 固有ルール

### データベース操作
- ORMを通じた安全なクエリのみ
- 生SQLの直接実行禁止
- トランザクション境界の明確化

### API設計
- RESTful設計に準拠
- バージョニング戦略: /api/v1/
- レート制限とエラーハンドリング必須
```

### 言語固有の調整
```bash
# Python プロジェクトの場合
sed -i 's/\[TEST_FRAMEWORK\]/pytest/g' CLAUDE.md
sed -i 's/\[LINT_COMMAND\]/ruff check/g' CLAUDE.md

# JavaScript プロジェクトの場合  
sed -i 's/\[TEST_FRAMEWORK\]/Jest/g' CLAUDE.md
sed -i 's/\[LINT_COMMAND\]/eslint src\//g' CLAUDE.md

# VBA プロジェクトの場合
sed -i 's/\[TEST_FRAMEWORK\]/Manual Testing/g' CLAUDE.md
sed -i 's/\[MIN_COVERAGE\]/70/g' CLAUDE.md  # VBAは要求緩和
```

## 📋 チェックリスト

### 新プロジェクト作成時
- [ ] CLAUDE.md.template をコピー
- [ ] 基本プレースホルダーを置換
- [ ] プロジェクト固有ルールを追加
- [ ] 技術スタック固有の設定
- [ ] トラブルシューティング情報を更新
- [ ] 関連ドキュメントリンクを設定

### テンプレート更新時
- [ ] 既存プロジェクトへの影響確認
- [ ] バージョン管理（ADRでの記録）
- [ ] プレースホルダーの一貫性確認
- [ ] 実際のプロジェクトでの動作確認

## 🎨 追加予定テンプレート

### 📄 issue_templates.md
**予定**: GitHub Issue テンプレート
- 新機能要求テンプレート
- バグ報告テンプレート  
- TDD要求仕様テンプレート

### 🔄 github_actions.yml
**予定**: GitHub Actions ワークフロー
- Claude Code 連携設定
- 自動テスト・デプロイ
- 品質ゲート統合

### 📝 document_structure.md
**予定**: ドキュメント構造テンプレート
- プロジェクトREADME
- API仕様書フォーマット
- アーキテクチャ文書

## 🔗 関連リンク

- **[Governance](../../governance/)** - 意思決定記録・ADR
- **[Hooks](../../hooks/)** - 自動品質ガード
- **[Operations](../03_operations/)** - 日常運用ガイド
- **[Reference](../04_reference/)** - 技術詳細・理論

---

*最終更新: 2025-07-10*