---
title: "AI駆動開発ワークスペース"
status: "active"
category: "quickstart"
created: "2025-07-10"
updated: "2025-07-14"
tags: ["workspace", "claude-code", "tdd", "yagni", "governance"]
priority: "high"
---

# AI駆動開発ワークスペース

> **目標**: TDD × YAGNI × 自動ガードを効かせた Claude Code 開発フローを「再現性高く」回せる状態にする

## 🚀 クイックスタート (3 Steps)

1. **クローン**: `git clone <this-repo> && cd workspace`
2. **VS Code**: `code .` で開く  
3. **開始**: [governance/README.md](./governance/README.md) を参照

**現在の状況**: 基盤システムは設計完了、実装は段階的に進行中

## 📋 開発環境要件

### 必須ツール
- **OS**: Windows 10+ / macOS 10.15+ / Ubuntu 20.04+
- **Git**: 2.30+
- **Node.js**: 18+ (npm 8+)
- **Python**: 3.9+ (pytest)
- **Docker**: 20.10+ (Docker Compose)

### 推奨 VS Code Extensions
- Claude Code (公式)
- GitLens
- Docker
- Python/JavaScript 用拡張

## 📁 ワークスペース構造

```
workspace/
├── governance/       # 議事録・ADR・意思決定記録
│   ├── README.md     # ガバナンス概要・手順
│   ├── adr/          # アーキテクチャ決定記録
│   └── mtg_minutes/  # 会議議事録
├── projects/         # 各プロジェクト配置場所
│   ├── README.md     # プロジェクト管理ガイド
│   └── sample-project/ # デモ用プロジェクト
├── schemas/          # Front-Matter検証スキーマ
│   ├── README.md     # スキーマ仕様
│   └── *.schema.json # JSON スキーマ定義
├── scripts/          # 自動化スクリプト
│   └── doc_inventory.py # 文書複雑性分析
├── CLAUDE.md         # AI開発憲法
└── README.md         # このファイル
```

## 🎯 開発原則

- **TDD**: テスト駆動開発を徹底
- **YAGNI**: 必要な機能のみ実装  
- **KISS**: シンプルな設計を維持

詳細は [CLAUDE.md](./CLAUDE.md) を参照してください。

## 🔗 関連ドキュメント

- **ガバナンス**: [governance/README.md](./governance/README.md) - 意思決定記録・運用手順
- **プロジェクト管理**: [projects/README.md](./projects/README.md) - 個別プロジェクト統合
- **文書品質管理**: [schemas/README.md](./schemas/README.md) - Front-Matter標準
- **プロジェクト憲法**: [CLAUDE.md](./CLAUDE.md) - AI開発の基本原則

## 🚀 現在の実装状況

### ✅ 完了済み
- **ガバナンス基盤**: ADR管理、意思決定記録、会議管理
- **文書品質制御**: スキーマ定義、複雑性分析システム
- **プロジェクト憲法**: TDD・YAGNI・自動ガード原則

### 🔄 実装中
- **Hook システム**: 品質ガード自動化（設計完了）
- **Claude Code 統合**: コマンド・テンプレート（設計完了）
- **CI/CD パイプライン**: GitHub Actions 自動化（設計完了）

### 📋 次のステップ
1. Hook システムの実装 → 品質ガードの自動化
2. Claude Code コマンドの実装 → 開発フローの標準化
3. CI/CD パイプラインの構築 → 継続的品質管理

---

🚀 **今すぐ始める**: [governance/README.md](./governance/README.md) で開発手順を確認