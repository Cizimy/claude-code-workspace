# Governance（ガバナンス）

> **目的**: プロジェクトの意思決定、議事録、技術的決定を体系的に管理し、透明性と追跡可能性を確保する

## 📁 ディレクトリ構造

```
governance/
├── README.md                    # 本ファイル
├── decision_log.md              # 意思決定の時系列サマリ
├── adr/                         # Architecture Decision Records
│   └── 000-claude-code-adoption.md
└── mtg_minutes/                 # ミーティング議事録
    └── (YYYY-MM-DD-topic.md)
```

## 🎯 各ディレクトリの役割

### ADR (Architecture Decision Records)
- **目的**: 技術的・アーキテクチャ的決定の記録
- **形式**: [ADRフォーマット](https://adr.github.io/) に準拠
- **命名**: `NNN-title.md` (例: `000-claude-code-adoption.md`)
- **レビュー**: 90日ごとの定期見直し

### Meeting Minutes
- **目的**: 定例・臨時ミーティングの議事録
- **形式**: `YYYY-MM-DD-topic.md`
- **内容**: 決定事項、アクションアイテム、次回課題

### Decision Log
- **目的**: 全決定事項の時系列管理
- **更新**: ADR作成時・重要決定時に即座更新
- **レビュー**: 月次で実装状況確認

## 🔄 運用フロー

### 新しい技術決定時
1. **Issue作成** → 議論 → **ADR起票**
2. **ADR承認後** → `decision_log.md` 更新
3. **必要に応じて** → プロジェクトの `CLAUDE.md` 更新

### 定期レビュー
- **月次レビュー**: 毎月10日に実装状況確認
- **四半期レビュー**: 90日ごとにADRの有効性評価
- **年次レビュー**: 全体的なガバナンス体制の見直し

## 📋 テンプレート

### ADRテンプレート
```markdown
# ADR-NNN: [決定事項のタイトル]

## Status
[Proposed | Accepted | Rejected | Superseded]

## Date
YYYY-MM-DD

## Context
[決定が必要になった背景・課題]

## Decision
[決定内容]

## Consequences
[この決定による影響・メリット・デメリット]

## Implementation Plan
[実装計画]

## Related Documents
[関連文書]

## Review
[レビュー予定日・成功指標]
```

### Meeting Minutes テンプレート
```markdown
# ミーティング議事録 - YYYY-MM-DD

## 基本情報
- **日時**: YYYY-MM-DD HH:MM
- **参加者**: [参加者リスト]
- **目的**: [ミーティングの目的]

## 議事内容
### 討議事項
1. [項目1]
2. [項目2]

### 決定事項
1. [決定1] → ADR-NNN で詳細記録
2. [決定2]

### アクションアイテム
- [ ] [TODO1] (担当者: XXX, 期限: YYYY-MM-DD)
- [ ] [TODO2] (担当者: XXX, 期限: YYYY-MM-DD)

### 次回課題
1. [課題1]
2. [課題2]

## 次回予定
- **日時**: YYYY-MM-DD HH:MM
- **主要議題**: [次回の主要議題]
```

## 🔗 関連リンク

- **[ADR Repository](adr/)** - すべてのアーキテクチャ決定記録
- **[Decision Log](decision_log.md)** - 意思決定の時系列サマリ
- **[プロジェクトCLAUDE.md](../CLAUDE.md)** - ワークスペース全体の開発指針

---

*最終更新: 2025-07-10*