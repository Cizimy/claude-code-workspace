# ADR-004: AI完璧主義防止システムのガバナンス統合決定

## Status
Accepted

## Date
2025-07-14

## Context

### 統合の必要性
ADR-003で決定されたAI完璧主義防止システムを既存のガバナンス体制と統合し、一元的な品質管理システムを構築する必要がある。

### 現在のガバナンス構造
```
Workspace Layer: 共通設定・横断ツール・品質基準
Governance Layer: 意思決定記録・品質標準・改善プロセス管理  
Project Layer: 個別実装・プロジェクト固有制約・具体的品質測定
```

### 既存システムとの関係
- **Phase 6 継続改善システム** (ADR-002): 改善事項追跡・効果測定
- **TDD × YAGNI × Hooks アーキテクチャ**: 3層品質制御システム
- **複雑性制御アーキテクチャ**: 包括的複雑性管理フレームワーク

### 課題
1. **分散した管理**: Hook設定、憲法更新、運用手順が分散
2. **一貫性の確保**: 新システムと既存ガバナンスの整合性
3. **変更管理**: 複数ファイルの同期更新とバージョン管理

## Decision

AI完璧主義防止システムを既存ガバナンス体制に統合し、以下の統一管理体制を確立する：

### 1. プロジェクト憲法の統合更新

#### CLAUDE.md への新セクション追加
```markdown
## AI完璧主義症候群対策

### ⚠️ 禁止事項
- **95%以上の完璧を追求しない**: 95%で十分です
- **推測実装禁止**: "将来必要かも"で実装しない  
- **大量ドキュメント作成禁止**: 5ファイル以上の同時作成不可
- **長期計画作成禁止**: 2026年以降の計画は作成しない

### 🔍 自己チェック必須項目
作業前に以下を自問してください：
1. **今すぐ使うか？** → NO なら実装しない
2. **実証されているか？** → NO なら仮説扱い  
3. **最もシンプルか？** → NO なら分割検討
4. **本当に必要か？** → 疑問があれば実装しない

### 📏 品質基準
- **テストカバレッジ**: 60%以上（100%不要）
- **ドキュメント**: 必要最小限のみ
- **実装範囲**: Issue記載分のみ
- **リファクタリング**: 動作優先、美化は後回し
```

### 2. Hook設定の統合管理

#### .claude/settings.json への統合
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|MultiEdit",
        "hooks": [
          {"command": ".claude/hooks/pre-tool/tdd-guard.sh"},
          {"command": ".claude/hooks/pre-tool/constitution-guard.sh"}
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|MultiEdit", 
        "hooks": [{"command": ".claude/hooks/post-tool/unused-detector.sh"}]
      }
    ],
    "Stop": [
      {
        "hooks": [{"command": ".claude/hooks/stop/coverage-check.sh"}]
      }
    ]
  }
}
```

### 3. ガバナンス文書の体系化

#### ディレクトリ構造
```
governance/
├── adr/
│   ├── 003-ai-perfectionism-prevention-system.md
│   └── 004-governance-integration-ai-perfectionism.md
├── decision_log.md (更新)
└── constitution_integration_checklist.md (新規)
```

#### 参照文書の体系化
```
.claude/docs/
├── 03_operations/
│   └── ai_perfectionism_monitoring.md (新規)
└── 04_reference/
    └── constitution-guard-system.md (新規)
```

### 4. 変更管理プロセス

#### 統合チェックリスト
1. **CLAUDE.md更新** → 憲法セクション追加確認
2. **Hook設定変更** → settings.json 整合性確認
3. **ガバナンス記録** → ADR・decision_log 同期更新
4. **文書リンク** → 相互参照の一貫性確認

#### バージョン管理戦略
- **原子的コミット**: 関連ファイルの一括更新
- **タグ付け**: `ai-perfectionism-v1.0` での統合版管理
- **ロールバック**: 問題発生時の一括復元手順

## Consequences

### 正の影響

#### 1. 統一された品質管理
- **一元的Hook管理**: 全品質ガードの統合制御
- **憲法の一貫性**: プロジェクト全体での統一された原則適用
- **変更の同期**: 関連ファイルの一括更新による整合性保証

#### 2. ガバナンス体制の強化
- **透明性向上**: 全決定事項のADR記録
- **追跡可能性**: decision_log での時系列管理
- **改善サイクル**: Phase 6システムとの統合による継続的改善

#### 3. 運用効率の向上
- **設定の標準化**: 新プロジェクトでの即座適用
- **トラブルシューティング**: 統一された問題解決手順
- **知識共有**: 体系化された文書による学習支援

### 負の影響とリスク軽減

#### 1. 初期導入コスト
- **リスク**: Hook統合・設定変更の複雑性
- **軽減策**: 段階的導入とロールバック手順の準備

#### 2. 既存ワークフローへの影響
- **リスク**: 開発者の作業フロー変更
- **軽減策**: 詳細な移行ガイドと十分な試用期間

#### 3. システム複雑性の増大
- **リスク**: Hook数増加による保守負担
- **軽減策**: 統合Hook設計による管理対象の最小化

## Implementation Plan

### Phase 1: 基盤統合（即座実施）
1. **CLAUDE.md更新**: AI完璧主義対策セクション追加
2. **constitution-guard.sh作成**: 新Hook実装
3. **settings.json統合**: Hook設定の一元化

### Phase 2: ガバナンス文書整備（1週間）
1. **運用手順書作成**: ai_perfectionism_monitoring.md
2. **技術仕様書作成**: constitution-guard-system.md
3. **decision_log更新**: 統合決定事項の記録

### Phase 3: 検証・最適化（1ヶ月）
1. **統合テスト**: 全Hook連携動作確認
2. **効果測定**: KPI収集・分析
3. **最適化**: パフォーマンス・精度調整

## Related Documents

### 基盤ADR
- [ADR-000: Claude Code採用決定](000-claude-code-adoption.md)
- [ADR-002: 継続改善システム](002-continuous-improvement-system.md)
- [ADR-003: AI完璧主義防止システム](003-ai-perfectionism-prevention-system.md)

### 実装参照
- [複雑性制御アーキテクチャ](../../.claude/tmp/complexity_control_architecture.md)
- [AI完璧主義防止計画](../../.claude/tmp/ai_perfectionism_prevention_plan.md)

### 運用文書（実装予定）
- [AI完璧主義監視手順](../../.claude/docs/03_operations/ai_perfectionism_monitoring.md)
- [Constitution Guard技術仕様](../../.claude/docs/04_reference/constitution-guard-system.md)

## Review

### 定期レビュー
- **月次レビュー**: 統合システムの動作状況確認
- **四半期レビュー**: ガバナンス体制の有効性評価
- **年次レビュー**: 全体アーキテクチャの見直し

### 成功指標
- **Hook統合成功率**: 100% (全Hook正常動作)
- **憲法適用一貫性**: 95%+ (プロジェクト間一貫性)
- **ガバナンス文書同期**: 100% (関連文書の整合性)
- **開発者満足度**: 80%+ (新システムへの適応)

---

*このADRは、AI完璧主義防止システムの既存ガバナンス体制への統合により、統一された品質管理システムの構築を目的として作成されました。*