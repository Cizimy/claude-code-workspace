# AI駆動開発ワークスペース

> **目標**: TDD × YAGNI × 自動ガードを効かせた Claude Code 開発フローを「再現性高く」回せる状態にする

## 🚀 クイックスタート (3 Steps)

1. **クローン**: `git clone <this-repo> && cd workspace`
2. **VS Code**: `code .` で開く  
3. **開始**: `.claude/docs/01_quickstart/README.md` を参照

新人の PC で **1 時間以内に再現可能** であることが目標です。

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
├── .claude/          # Claude Code 共通設定
│   ├── hooks/        # 品質ガードスクリプト
│   ├── docs/         # セットアップガイド
│   └── settings.json # ツール権限設定
├── governance/       # 議事録・ADR  
├── projects/         # 各プロジェクト (worktree)
├── CLAUDE.md         # AI開発憲法
└── README.md         # このファイル
```

## 🎯 開発原則

- **TDD**: テスト駆動開発を徹底
- **YAGNI**: 必要な機能のみ実装  
- **KISS**: シンプルな設計を維持

詳細は [CLAUDE.md](./CLAUDE.md) を参照してください。

## 🔗 関連ドキュメント

- **セットアップ**: [.claude/docs/01_quickstart/README.md](./.claude/docs/01_quickstart/README.md)
- **開発ガイド**: [governance/README.md](./governance/README.md)
- **プロジェクト憲法**: [CLAUDE.md](./CLAUDE.md)

---

🚀 **今すぐ始める**: [クイックスタートガイド](./.claude/docs/01_quickstart/README.md)