# ADR-000: Claude Code AI駆動開発フローの採用

## Status
Accepted

## Date
2025-07-10

## Context
個人開発のWebアプリ/APIバックエンドプロジェクトにおいて、AI駆動型の開発フローを構築する必要が生じている。複数のプロジェクト（danbooru_advanced_wildcard, pdi）を横断的に管理し、品質を保ちながら開発効率を向上させることが目標である。

### 課題
- 手動でのコード品質管理による開発効率の低下
- テスト駆動開発（TDD）とYAGNI原則の一貫した適用が困難
- 複数プロジェクト間での開発プロセスの統一が必要
- 人的リソースの制約により、継続的な品質監視が困難

### 要求事項
- **テスト駆動開発（TDD）**の徹底
- **YAGNI原則**の遵守による複雑性の抑制
- **自動ガード**による品質管理の自動化
- **GitHub Issue駆動**の開発フロー
- **複数プロジェクト対応**のワークスペース設計

## Decision
Claude Code を中心とした AI駆動開発フローを採用する。

### 採用理由
1. **TDD × YAGNI × 自動ガード の統合実現**
   - Claude Codeの持つコンテクスト理解能力により、テスト先行開発が自動化可能
   - CLAUDE.mdによるプロジェクト憲法で制約を明文化
   - Hooksによる決定論的な品質ガードの実現

2. **GitHub Actionsとの統合による自動化**
   - Issue駆動開発からPR作成・レビューまでの完全自動化
   - Claude Codeによる継続的なコード改善とリファクタリング

3. **実証済みの技術基盤**
   - Anthropic社の公式ツールとしての信頼性
   - 既存プロジェクトでの成功実績

### 実装アプローチ
```yaml
# 実装方針
architecture:
  workspace_layer: "横断共通ルール・ツール・フローの一元管理"
  governance_layer: "意思決定記録・議事録・決定ログの管理"
  project_layer: "個別実装・テスト・CI"

core_principles:
  - "CLAUDE.mdによるプロジェクト憲法の明文化"
  - "Hooksによる自動チェック・制御"
  - "Issue → PR → Merge の完全自動化"
  - "テスト先行・必要最小限実装の徹底"

quality_gates:
  - "TDD違反検出（PreToolUseフック）"
  - "未使用コード検出（PostToolUseフック）"
  - "カバレッジチェック（Stopフック）"
```

## Consequences

### Positive
- **開発効率向上**: AI による自動実装とテストで開発速度が向上
- **品質安定化**: 自動ガードにより人的ミスが大幅減少
- **知識継承**: CLAUDE.mdとADRによる設計思想の明文化
- **プロセス標準化**: 複数プロジェクト間での一貫した開発プロセス

### Negative
- **学習コスト**: 新しいツールチェーンの習得が必要
- **依存性リスク**: Claude Code APIへの依存度が高まる
- **初期セットアップコスト**: 環境構築とルール整備に時間が必要

### Mitigation
- **段階的導入**: 既存プロジェクトを順次移行し、リスクを最小化
- **フォールバック準備**: 従来の手動開発手法も並行維持
- **定期評価**: 90日ごとの効果測定と改善

## Implementation Plan
1. **Phase 1**: Workspace基盤構築（governance, hooks, docs構造）
2. **Phase 2**: テンプレート・コマンド整備
3. **Phase 3**: ドキュメント統合・実践ガイド作成
4. **Phase 4**: 検証・最適化・Git Worktree戦略評価

## Related Documents
- [AI駆動開発ワークフローの設計と運用指針](../tmp/archive/AI駆動開発ワークフローの設計と運用指針.md)
- [Claude Code 実践ドキュメント再編成計画書](../tmp/archive/Claude Code 実践ドキュメント再編成計画書.md)
- [アクションプラン](../tmp/archive/アクションプラン.md)
- [構想](../tmp/archive/構想.md)

## Review
- **Next Review Date**: 2025-10-10 (90日後)
- **Success Criteria**: 
  - 新機能実装時間の50%短縮
  - テストカバレッジ90%以上維持
  - バグ発生率の70%削減