# Projects Directory

このディレクトリは git worktree による個別プロジェクトの配置場所です。

## 設計方針

### Git Worktree による疑似モノレポ構成
```
workspace/                    # メインワークスペース (このリポジトリ)
├── .claude/                  # 共通Claude設定
├── governance/               # 意思決定記録・議事録
├── projects/                 # 個別プロジェクト配置場所
│   ├── danbooru_advanced_wildcard/  # Python プロジェクト (worktree)
│   ├── pdi/                         # VBA プロジェクト (worktree)
│   └── sample-project/              # サンプルプロジェクト (demo用)
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
# Claude設定継承
mkdir -p .claude/hooks_local
cp ../../.claude/docs/02_templates/CLAUDE.md.template .claude/CLAUDE.md
```

## 現在の状況

- **実プロジェクト**: 未配置（リモートリポジトリが必要）
- **サンプル**: demo用の構造のみ作成済み
- **設定**: worktree 統合手順を文書化

## 次のステップ

1. 実際のプロジェクトリポジトリが用意でき次第、上記手順で統合
2. プロジェクト固有のClaude設定をカスタマイズ
3. CI/CD統合と動作確認

*最終更新: 2025-07-13*