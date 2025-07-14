# ADR-005: ドキュメント複雑性制御システムの導入決定

## Status
Accepted

## Date
2025-07-14

## Context

### 問題の背景

Claude Code を用いたAI駆動開発において、ドキュメントの複雑性が急速に増大し、従来の「プレーンテキスト」運用では限界に達している：

#### 具体的な問題症状
1. **ファイル数・行数の急増**: 
   - `implementation_verification_sop.md` が 1,200行超
   - Hook スクリプトも 6枚に分散
   - 重複・リンク切れ・レビュー漏れが発生しやすい状況

2. **横串メタデータの手作業管理**:
   - ADR 4本と `decision_log.md` を手動同期
   - 人為ミスで一貫性を失いやすい

3. **ドキュメント⇄メトリクスの分離**:
   - 「違反ログ → SQLite ダッシュボード生成」構想が未接続
   - 解析系が増えるほど更新漏れが発生

### 複雑性の臨界点
> **目安**: 「Markdown が 100+ 枚 or 相互参照が 2 Hop 以上」で、テキストだけの運用コストが CI 時間 > 執筆時間になり始める

### 既存システムとの関係
- **ADR-003**: AI完璧主義防止システム（大量ドキュメント作成検出）
- **ADR-004**: ガバナンス統合体制（統一品質管理）
- **Phase 6継続改善**: 改善事項追跡システム

## Decision

ドキュメント複雑性制御システムを段階的に導入し、「**ハイブリッド: Markdown + SQLite/DuckDB でメタデータ集約**」アーキテクチャを採用する：

### 基本戦略
```
一次ソース Markdown + Front-Matter + 構造化レイヤー（SQLite） = 最小コスト・最大効果
```

### 段階導入モデル（6週間）

#### Week 1: Inventory & Analysis
**目的**: 現状のドキュメント複雑性を定量化
- **成果物**: `scripts/doc_inventory.py`
- **機能**: Markdown一覧・行数・内部リンクをCSV出力
- **効果**: 複雑性の可視化・問題箇所特定

#### Week 2: Front-Matter 標準化
**目的**: 検索キーを構造化
- **成果物**: `schemas/md-meta.schema.json`
- **機能**: 全Markdown冒頭に統一YAML付与
- **例**: `adr: 005`, `status: accepted`, `tags: [governance, complexity]`

#### Week 3: スキーマ検証CI追加
**目的**: 早期に整合性エラー検出
- **成果物**: `.github/workflows/docs-ci.yml`
- **機能**: `remark-lint-frontmatter-schema` で JSON Schema への自動lint
- **効果**: Front-Matter品質の自動保証

#### Week 4: メタデータDB化
**目的**: 横断検索・ダッシュボード
- **成果物**: `scripts/build_docs_db.py`
- **機能**: Python で front-matter を抽出 → SQLite に `INSERT`
- **統合**: 既存 Step F の SQLite KPI 基盤に同居

#### Week 5: 静的サイト生成
**目的**: 閲覧性・全文検索
- **成果物**: `mkdocs.yml`
- **機能**: MkDocs で "人に読ませる面" を自動ビルド
- **拡張**: Algolia などで検索機能追加

#### Week 6+: 知識グラフ連携（任意）
**目的**: 複雑な依存の可視化
- **成果物**: `neo4j-import/`
- **機能**: ADR → 決定 → Hook → KPI を Neo4j で関係性クエリ

### AI完璧主義防止システムとの統合
- **constitution-guard.sh** で大量ドキュメント作成を事前検出
- **Front-Matter標準化** で推測的ドキュメント作成を制約
- **SQLite統合** で既存品質メトリクスとの一元管理

## Consequences

### 期待される正の影響

#### 1. 段階的複雑性制御
- **Week 1-2**: 現状把握・標準化で基盤構築
- **Week 3-4**: 自動化・DB化で運用効率向上
- **Week 5-6**: 可視化・検索で利用性向上

#### 2. 既存システムとの相乗効果
- **AI完璧主義防止**: 大量ドキュメント作成の事前ブロック
- **継続改善システム**: SQLite統合による改善メトリクス一元化
- **ガバナンス統合**: ADR・decision_log の自動同期

#### 3. 運用コストの最適化
- **diff追跡**: Markdownの一次ソース維持でGit履歴保持
- **権限流用**: 既存Git権限での編集制御
- **CI統合**: 既存GitHub Actions への追加のみ

### 潜在的な負の影響とリスク軽減策

#### 1. 初期導入コスト
- **リスク**: Front-Matter移行・スキーマ設計の工数
- **軽減策**: 段階的導入（Week 1-2は既存文書への影響最小）

#### 2. スキーマ保守負担
- **リスク**: JSON Schema・SQLiteスキーマの継続メンテナンス
- **軽減策**: 最小限の必須フィールドのみ定義、拡張は漸進的

#### 3. ツールチェーン複雑化
- **リスク**: 新しい依存関係（remark-lint, SQLite, MkDocs）
- **軽減策**: 既存 quality-gate.yaml / SQLite 構想の延長として統合

## Implementation Plan

### Phase 1: 基盤構築（Week 1-2）
1. **ドキュメント棚卸**: `doc_inventory.py` 作成・実行
2. **JSON Schema設計**: 最小限の必須フィールド定義
3. **Front-Matter試行**: 主要ADR・ガバナンス文書への適用

### Phase 2: 自動化統合（Week 3-4）
1. **CI統合**: GitHub Actions でスキーマ検証
2. **SQLite統合**: 既存KPI基盤への docs_index テーブル追加
3. **横断検索**: front-matter ベースのクエリ機能

### Phase 3: 可視化・拡張（Week 5-6）
1. **MkDocs統合**: 静的サイト自動生成
2. **Neo4j検証**: PoC実装・効果測定
3. **本格運用**: 全ワークスペースでの正式採用

## Success Metrics

### 定量指標
- **ドキュメント発見時間**: 50%削減（前: 手動検索、後: SQLiteクエリ）
- **メタデータ整合性**: 95%+（自動スキーマ検証）
- **CI実行時間**: 2分以内維持（軽量なlint追加）
- **横断検索精度**: 90%+（front-matterベースクエリ）

### 定性指標
- **開発者体験**: ドキュメント発見・編集の効率化
- **品質保証**: 自動検証による人為ミス削減
- **知識共有**: 構造化情報による学習支援
- **拡張性**: 新しいプロジェクト・メトリクスへの対応力

## Related Documents

### 基盤ADR
- [ADR-000: Claude Code採用決定](000-claude-code-adoption.md)
- [ADR-002: 継続改善システム](002-continuous-improvement-system.md)
- [ADR-003: AI完璧主義防止システム](003-ai-perfectionism-prevention-system.md)
- [ADR-004: ガバナンス統合](004-governance-integration-ai-perfectionism.md)

### 技術基盤参照
- [複雑性制御アーキテクチャ](../../.claude/tmp/complexity_control_architecture.md)
- [ドキュメント複雑性制御プラン](../../.claude/tmp/document_complexity_control_plan.md)

### 実装文書（作成予定）
- [ドキュメント複雑性監視手順](../../.claude/docs/03_operations/document_complexity_monitoring.md)
- [ドキュメント複雑性制御技術仕様](../../.claude/docs/04_reference/document-complexity-control-system.md)

## Review

### 定期レビュー
- **Week 3レビュー**: Front-Matter移行・CI統合状況確認
- **Week 6レビュー**: 全システム統合・効果測定
- **月次レビュー**: 運用状況・改善事項確認
- **四半期レビュー**: アーキテクチャ有効性・次期拡張検討

### 成功判定基準
- **基盤構築**: Week 2で JSON Schema・Front-Matter標準適用完了
- **自動化統合**: Week 4で CI統合・SQLite横断検索機能完成
- **運用開始**: Week 6で全ワークスペース正式採用
- **効果確認**: 3ヶ月後に定量・定性指標達成度評価

---

*このADRは、AI駆動開発における ドキュメント複雑性制御の段階的導入により、既存のガバナンス体制・品質管理システムとの統合を目的として作成されました。*