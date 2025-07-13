# 🗂️ リポジトリ戦略 - Git Worktree による疑似モノレポ

> **目的**: Git worktree を活用した「見た目モノレポ + 履歴独立」構成の技術詳細

## 🎯 戦略概要

### 採用理由
| 課題 | 従来手法の問題 | Git Worktree による解決 |
|------|-------------|-------------------|
| **巨大化回避** | モノレポの肥大・ビルド時間増大 | 履歴を独立保持、必要な部分のみ配置 |
| **並列作業** | ブランチ切替でのstash/commit強制 | 複数作業ツリーで並列開発可能 |
| **Disk効率** | プロジェクト数×リポジトリサイズ | 共有オブジェクトでディスク節約 |
| **開発体験** | プロジェクト間移動の手間 | 1ウィンドウで横断開発・検索 |

### アーキテクチャ
```
workspace/
├── .git/                 # Workspace 専用履歴
├── governance/           # 議事録・ADR
├── .claude/             # 共通設定・Hook
└── projects/            # 各プロジェクトの worktree
    ├── proj_a/          # ← proj_a.git の worktree
    ├── proj_b/          # ← proj_b.git の worktree
    └── proj_c/          # ← proj_c.git の worktree
```

## 🔧 技術実装詳細

### Git Worktree の基本構造
```bash
# Worktree 作成前
workspace/.git/objects/         # Workspace のオブジェクト

# Worktree 作成後
workspace/.git/objects/         # 全プロジェクトの共有オブジェクト
workspace/.git/worktrees/
├── proj_a/                    # proj_a worktree のメタデータ
│   ├── HEAD                   # 現在のブランチ
│   ├── commondir              # 共有ディレクトリのパス
│   └── gitdir                 # worktree のディレクトリ
├── proj_b/
└── proj_c/
```

### リモート設定の分離
```bash
# 各 worktree で独立したリモート設定
cd projects/proj_a
git remote -v
# origin  https://github.com/org/proj_a.git (fetch)
# origin  https://github.com/org/proj_a.git (push)

cd ../proj_b  
git remote -v
# origin  https://github.com/org/proj_b.git (fetch)
# origin  https://github.com/org/proj_b.git (push)
```

## 📋 セットアップ手順

### 1. 初期 Workspace 構築
```bash
# Workspace リポジトリの準備
mkdir workspace && cd workspace
git init
git remote add origin https://github.com/org/workspace.git

# 基本構造の作成
mkdir -p {governance,projects,.claude}
echo "# AI駆動開発ワークスペース" > README.md
git add . && git commit -m "init: ワークスペース初期化"
git push -u origin main
```

### 2. プロジェクト Worktree 追加
```bash
# プロジェクトリポジトリをリモートとして追加
git remote add proj_a https://github.com/org/proj_a.git
git fetch proj_a

# Worktree として配置
git worktree add projects/proj_a proj_a/main

# Worktree 内でのリモート設定
cd projects/proj_a
git remote set-url origin https://github.com/org/proj_a.git

# 動作確認
git status
git remote -v
```

### 3. 複数プロジェクト追加
```bash
# 追加プロジェクトの一括セットアップ
for project in proj_b proj_c proj_d; do
  echo "Setting up $project..."
  git remote add $project https://github.com/org/${project}.git
  git fetch $project
  git worktree add projects/$project ${project}/main
  
  cd projects/$project
  git remote set-url origin https://github.com/org/${project}.git
  cd ../..
done

# Worktree 一覧確認
git worktree list
```

## ⚙️ 運用フロー

### 日常開発フロー
```bash
# 1. VS Code でワークスペース全体を開く
code workspace.code-workspace

# 2. 特定プロジェクトでの作業
cd projects/proj_a
git switch -c feat/new-feature
# ... 開発作業 ...
git commit -m "feat: implement new feature"
git push -u origin feat/new-feature

# 3. 並列プロジェクト作業
cd ../proj_b
git switch -c fix/bug-123
# ... バグ修正作業 ...
git commit -m "fix: resolve issue #123"
git push -u origin fix/bug-123
```

### Claude Code 統合
```bash
# Claude による横断作業
@claude /workspace:security-review

# 特定プロジェクトの作業  
@claude /project:new-feature proj_a#456

# 複数プロジェクト影響の修正
@claude /workspace:dependency-update --security-only
```

## 🔒 セキュリティ・権限管理

### ブランチ保護設定
```bash
# 各プロジェクトで個別にブランチ保護
# projects/proj_a での設定例
cd projects/proj_a
gh api repos/:owner/proj_a/branches/main/protection \
  --method PUT \
  --input protection-rules.json
```

### アクセス制御
```json
// プロジェクト固有の .claude/settings.json
{
  "extends": "../../.claude/settings.json",
  "permissions": {
    "allowedPaths": ["./src", "./tests", "./docs"],
    "deniedPaths": [
      "../proj_b",    // 他プロジェクトへのアクセス禁止
      "../proj_c",
      "../../.git"    // Workspace Git への直接アクセス禁止
    ]
  }
}
```

### Hook による境界制御
```bash
#!/bin/bash
# .claude/hooks/pre-tool/project-boundary-guard.sh

TOOL_NAME="$1"
TARGET_PATH="$2"

# プロジェクト境界を超えたファイル操作を検出
current_project=$(basename "$PWD")
target_project=$(echo "$TARGET_PATH" | grep -o "projects/[^/]*" | cut -d'/' -f2)

if [[ -n "$target_project" ]] && [[ "$current_project" != "$target_project" ]]; then
  echo "ERROR: プロジェクト境界違反を検出" >&2
  echo "現在: $current_project, 対象: $target_project" >&2
  echo "プロジェクト間のクロス参照は禁止されています" >&2
  exit 2
fi
```

## 🚨 よくある問題と対策

### 問題 1: Workspace で git status に大量の untracked
**症状**: Workspace ルートで `git status` すると projects/ が全て untracked で表示

**対策**:
```bash
# .git/info/exclude に追記
echo "projects/**" >> .git/info/exclude

# または .gitignore に追記
echo "/projects/" >> .gitignore
git add .gitignore && git commit -m "ignore: add projects directory"
```

### 問題 2: 誤って Workspace リポジトリに Push
**症状**: プロジェクトの変更が workspace リポジトリに push される

**対策**:
```bash
# 各 worktree でリモート URL 確認・修正
cd projects/proj_a
git remote set-url origin https://github.com/org/proj_a.git

# Hook による自動チェック
cat > .claude/hooks/pre-tool/remote-check.sh << 'EOF'
#!/bin/bash
if [[ "$1" == "git" ]] && [[ "$2" == *"push"* ]]; then
  origin_url=$(git remote get-url origin)
  current_dir=$(basename "$PWD")
  
  if [[ "$origin_url" != *"$current_dir"* ]]; then
    echo "ERROR: リモート URL とディレクトリ名が不一致" >&2
    echo "現在のディレクトリ: $current_dir" >&2  
    echo "Origin URL: $origin_url" >&2
    exit 2
  fi
fi
EOF
chmod +x .claude/hooks/pre-tool/remote-check.sh
```

### 問題 3: VS Code Git 拡張の混乱
**症状**: VS Code で複数の .git ディレクトリを誤認識

**対策**:
```json
// .vscode/settings.json
{
  "git.detectSubmodules": false,
  "files.exclude": {
    "**/.git": true,           // ネストした .git を隠す
    "projects/*/.git": false   // worktree の .git は表示
  },
  "git.repositories": [
    "./",
    "./projects/proj_a",
    "./projects/proj_b"
  ]
}
```

### 問題 4: Hook の重複実行
**症状**: Workspace と Project の Hook が両方実行される

**対策**:
```bash
# Hook にスコープ制御を追加
#!/bin/bash
# Hook の重複実行防止
HOOK_SCOPE="${GIT_DIR:-$PWD}"
LOCK_FILE="/tmp/claude_hook_${HOOK_SCOPE//\//_}.lock"

if [[ -f "$LOCK_FILE" ]]; then
  echo "Hook already running in this scope" >&2
  exit 0
fi

echo $$ > "$LOCK_FILE"
trap "rm -f $LOCK_FILE" EXIT

# 実際の Hook 処理...
```

## 📊 パフォーマンス最適化

### オブジェクト共有の効果測定
```bash
# 従来方式のディスク使用量 (独立 clone)
for proj in proj_a proj_b proj_c; do
  du -sh /path/to/individual/${proj}/.git
done
# 結果例: 150MB + 200MB + 180MB = 530MB

# Worktree 方式のディスク使用量
du -sh workspace/.git
# 結果例: 350MB (34% 削減)
```

### パフォーマンス監視
```bash
# Worktree 操作の性能測定
time git worktree add projects/new_project new_project/main
# real: 0m3.245s (clone より高速)

# 横断検索の性能
time grep -r "function_name" projects/
# worktree: 1.2s vs 個別検索: 3.8s
```

## 🔄 維持・管理

### 定期メンテナンス
```bash
#!/bin/bash
# scripts/worktree-maintenance.sh

echo "=== Worktree メンテナンス開始 ==="

# 1. 孤立した worktree の清掃
git worktree prune

# 2. 不要なリモート参照の削除
git remote prune origin

# 3. オブジェクト最適化
git gc --aggressive

# 4. Worktree 健全性チェック
for worktree in projects/*/; do
  echo "Checking $worktree..."
  cd "$worktree"
  
  # リモート URL 確認
  origin_url=$(git remote get-url origin 2>/dev/null || echo "NOT_SET")
  expected_url="https://github.com/org/$(basename $PWD).git"
  
  if [[ "$origin_url" != "$expected_url" ]]; then
    echo "WARNING: Incorrect remote URL in $worktree"
    echo "  Current: $origin_url"
    echo "  Expected: $expected_url"
  fi
  
  cd - >/dev/null
done

echo "=== メンテナンス完了 ==="
```

### バックアップ戦略
```bash
# Workspace 全体のバックアップ
tar --exclude='.git/objects' \
    --exclude='node_modules' \
    --exclude='__pycache__' \
    -czf "workspace-backup-$(date +%Y%m%d).tar.gz" workspace/

# 各プロジェクトの独立バックアップ（通常の Git バックアップ）
for project_dir in projects/*/; do
  project_name=$(basename "$project_dir")
  echo "Backing up $project_name..."
  git -C "$project_dir" bundle create "../backups/${project_name}-$(date +%Y%m%d).bundle" --all
done
```

---

**運用指針**: Git worktree の特性を理解し、適切な境界制御と定期メンテナンスにより、スケーラブルな開発環境を維持してください。問題発生時は worktree を個別に削除・再作成することで迅速な復旧が可能です。