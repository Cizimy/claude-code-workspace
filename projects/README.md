---
title: "Projects Directory"
status: "active"
category: "reference"
created: "2025-07-13"
updated: "2025-07-14"
tags: ["projects", "worktree", "integration"]
priority: "medium"
---

# Projects Directory

このディレクトリは git worktree による個別プロジェクトの配置場所です。

## 設計方針

### Git Worktree による疑似モノレポ構成
```
workspace/                    # メインワークスペース (このリポジトリ)
├── governance/               # 意思決定記録・議事録
├── projects/                 # 個別プロジェクト配置場所
│   ├── danbooru_advanced_wildcard/  # Python プロジェクト (worktree) - 未配置
│   ├── pdi/                         # VBA プロジェクト (worktree) - 未配置
│   └── sample-project/              # サンプルプロジェクト (demo用)
├── schemas/                  # Front-Matter検証スキーマ
├── scripts/                  # 自動化スクリプト
└── README.md
```

## プロジェクト追加手順

### 既存プロジェクトの統合
```bash
# 1. リモートとして追加
git remote add proj_name https://github.com/your-org/proj_name.git
git fetch proj_name

# 2. worktree として配置
git worktree add projects/proj_name proj_name/main

# 3. リモート設定調整
cd projects/proj_name
git remote set-url origin https://github.com/your-org/proj_name.git
```

### プロジェクト固有設定
```bash
# プロジェクト固有のClaude設定（将来実装予定）
mkdir -p .claude/hooks_local
# 将来: テンプレートからカスタマイズ
```

## 現在の状況

- **実プロジェクト**: 未配置（リモートリポジトリが必要）
- **サンプル**: demo用の基本構造のみ作成済み
- **設定**: worktree 統合手順を文書化
- **Claude統合**: 設計完了、実装は今後

## 次のステップ

1. 実際のプロジェクトリポジトリが用意でき次第、上記手順で統合
2. Claude Code統合システムの実装
3. プロジェクト固有設定のカスタマイズ
4. CI/CD統合と動作確認

*最終更新: 2025-07-14*