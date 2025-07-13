# ADR-001: ガバナンス CI 自動検証システムの導入

## Status
Proposed

## Date
2025-07-13

## Context
Phase 2 ガバナンス整備において、ADR (Architecture Decision Records) と Meeting Minutes の品質管理を自動化する必要が生じている。現在は手動でのファイル形式チェックと整合性確認を行っているが、以下の課題がある：

### 課題
- **ADR 形式不整合**: Status, Context, Decision セクションの漏れ
- **ファイル命名規則違反**: NNN-kebab-case.md 形式の不統一
- **内部リンク切れ**: ADR間参照の管理ミス
- **Meeting Minutes 品質**: テンプレート逸脱とフォーマット問題

### 要求事項
- **自動形式検証**: 必須セクションの存在確認
- **命名規則強制**: CI による自動チェック
- **リンク整合性**: ADR間参照の自動検証
- **CI統合**: GitHub Actions との完全統合

## Decision
GitHub Actions による **Governance CI ワークフロー** を導入し、ADR と Meeting Minutes の品質を自動検証する。

### 実装方針
```yaml
# 実装コンポーネント
adr_validation:
  - "必須セクション検証 (Status, Context, Decision)"
  - "ADR番号重複チェック"
  - "メタデータ形式検証"

file_naming_lint:
  - "ADR: NNN-kebab-case.md 形式強制"
  - "Meeting Minutes: YYYY-MM-DD-topic.md 形式確認"

governance_links:
  - "ADR間内部リンク検証"
  - "Decision Log との整合性確認"
  - "関連文書リンクチェック"
```

### 検証レベル
1. **Error (CI 失敗)**: 必須セクション欠如、命名規則違反
2. **Warning (CI 通過)**: 推奨事項の逸脱、軽微な形式問題
3. **Info (CI 通過)**: ベストプラクティス提案

## Consequences

### Positive
- **品質向上**: ADR・議事録の形式統一と品質安定化
- **効率化**: 手動チェック作業の自動化
- **信頼性**: CI による決定論的な検証
- **保守性**: ドキュメントリンクの自動管理

### Negative
- **CI 複雑化**: 新しいワークフローによる CI 時間増加
- **初期設定コスト**: 検証ルールの策定と調整工数
- **偽陽性リスク**: 過度に厳格なチェックによる開発阻害

### Mitigation
- **段階的導入**: Warning レベルから開始し、徐々に厳格化
- **例外処理**: 特定ファイルの検証スキップ機能
- **調整可能性**: 閾値とルールの設定ファイル化

## Implementation Plan

### Phase 1: 基本検証 (Day 3)
```bash
# 基本的な ADR 形式チェック
.github/workflows/governance.yml:
  - ADR 必須セクション検証
  - ファイル命名規則チェック
  - 基本的なMarkdown形式検証
```

### Phase 2: 高度な検証 (Day 4)
```bash
# リンク整合性とメタデータ検証
governance_links:
  - ADR間相互参照検証
  - Decision Log 自動同期チェック
  - 外部リンク存在確認
```

### Phase 3: 運用最適化 (継続)
```bash
# CI 最適化と運用改善
optimization:
  - 検証時間短縮
  - エラーメッセージ改善
  - 自動修正提案機能
```

## Related Documents
- [ADR-000: Claude Code AI駆動開発フローの採用](000-claude-code-adoption.md)
- [Phase 2 ガバナンス設定ドキュメント](../../.claude/docs/01_quickstart/governance_setup.md)
- [Meeting Minutes: 2025-07-13](../mtg_minutes/2025-07-13-governance-setup.md)

## Implementation Details

### GitHub Actions Workflow
```yaml
# .github/workflows/governance.yml 実装内容
triggers:
  - governance/** パス変更時
  - PR 時の自動検証

jobs:
  adr-validation:
    - adr-tools による形式検証
    - 必須セクション存在確認
    - ADR番号重複チェック
    
  file-naming-lint:
    - 命名規則の自動検証
    - 正規表現によるパターンマッチ
    
  governance-links:
    - markdown-link-check による リンク検証
    - ADR間参照の整合性確認
```

### 成功指標
- **CI通過率**: 95% 以上のPR通過
- **検証時間**: 平均 2分以内の完了
- **偽陽性率**: 5% 以下の誤検出

## Review
- **Next Review Date**: 2025-08-13 (30日後)
- **Success Criteria**: 
  - ガバナンス文書品質の向上確認
  - CI による自動検証の安定運用
  - 開発効率への影響評価