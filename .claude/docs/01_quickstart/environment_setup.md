# 🔧 環境セットアップ (Day 0-2)

> **目標**: Claude Code の基本環境を構築し、TDD・YAGNI・自動ガードの基盤を整備

## 📋 Day 0: 事前準備

### 0-1. リポジトリ戦略の確定
**タスク**: `workspace` 親リポジトリ + `projects/*` を git worktree で置く方針をチーム合意

**手順**:
1. プロジェクト構成を決定
   ```
   workspace/
   ├── .claude/          # Claude Code 共通設定
   ├── governance/       # 議事録・ADR  
   └── projects/         # 各プロジェクト (worktree)
   ```

2. チーム内での合意形成
   - 疑似モノレポ構成のメリット・デメリット説明
   - 既存プロジェクトの移行計画確認

**完了目安**: 方針決定・ドキュメント化

### 0-2. 権限・トークン整理
**タスク**: GitHub PAT・Claude Code 用 API Key の準備

**手順**:
1. **GitHub Personal Access Token (PAT)** 作成
   - Settings → Developer settings → Personal access tokens
   - 必要な権限: `repo`, `workflow`

2. **Claude API Key** 取得  
   - Anthropic Console でプロジェクト作成
   - API Key 発行・保存

3. **Secrets 設定**
   ```bash
   # GitHub リポジトリの Settings → Secrets and variables → Actions
   GITHUB_TOKEN=<your-github-pat>
   CLAUDE_API_KEY=<your-claude-api-key>
   ```

**完了目安**: Secrets 発行・設定完了

### 0-3. ローカル開発要件の宣言
**タスク**: 推奨 OS/CLI/VS Code extensions を README に記載

**手順**:
1. **必須ツール**
   ```markdown
   ## 開発環境要件
   - OS: Windows 10+ / macOS 10.15+ / Ubuntu 20.04+
   - Git: 2.30+
   - Node.js: 18+ (npm 8+)
   - Python: 3.9+ (pytest)
   - Docker: 20.10+ (Docker Compose)
   ```

2. **推奨 VS Code Extensions**
   ```markdown
   - Claude Code (公式)
   - GitLens
   - Docker
   - Python/JavaScript 用拡張
   ```

**完了目安**: README 草稿作成

---

## 📋 Day 1-2: Workspace レイヤ初期化

### 1-1. GitHub リポジトリ作成
**タスク**: `workspace/` を GitHub に新規作成

**手順**:
```bash
# 1. ローカルでリポジトリ初期化
mkdir workspace && cd workspace
git init
git remote add origin https://github.com/your-org/workspace.git

# 2. 初期コミット
echo "# AI駆動開発ワークスペース" > README.md
git add README.md
git commit -m "init: ワークスペース初期化"
git push -u origin main
```

**完了目安**: 空リポジトリの作成

### 1-2. トップ 3 ファイルの雛形作成
**タスク**: README.md, CLAUDE.md, docs/20_environment/local_setup.md を作成

**手順**:
1. **README.md** (3-Step Quick Start)
   ```markdown
   # AI駆動開発ワークスペース
   
   ## クイックスタート
   1. `git clone && cd workspace`
   2. `code .` (VS Code で開く)
   3. `.claude/docs/00_START_HERE.md` を参照
   ```

2. **CLAUDE.md** (KISS/TDD/YAGNI 原則)
   ```markdown
   # プロジェクト憲法
   
   ## 開発原則
   - **TDD**: テスト駆動開発を徹底
   - **YAGNI**: 必要な機能のみ実装
   - **KISS**: シンプルな設計を維持
   
   ## 違反ペナルティ
   - テスト無し実装 → Hook でブロック
   - 未使用コード → 自動検出・削除要請
   ```

3. **docs/20_environment/local_setup.md**
   ```markdown
   # ローカル環境セットアップ
   
   ## OS別インストール手順
   ### Windows
   ### macOS  
   ### Linux
   ```

**完了目安**: ファイル反映・コミット

### 1-3. Claude Code 設定ファイル生成
**タスク**: `.claude/settings.json` の作成

**手順**:
```bash
# ディレクトリ作成
mkdir -p .claude

# 設定ファイル作成
cat > .claude/settings.json << 'EOF'
{
  "allowedTools": [
    "bash",
    "git", 
    "pytest",
    "npm",
    "python"
  ],
  "hookPaths": [
    "../.claude/hooks"
  ],
  "permissions": {
    "fileOperations": true,
    "networkAccess": false,
    "systemCommands": "restricted"
  }
}
EOF
```

**完了目安**: commit 完了

### 1-4. Hooks 雛形スクリプト作成
**タスク**: 基本的な品質ガード Hook を 3 本作成

**手順**:
```bash
# Hook ディレクトリ作成
mkdir -p .claude/hooks/{pre-tool,post-tool,stop}

# 1. TDD ガード (pre-tool)
cat > .claude/hooks/pre-tool/tdd-guard.sh << 'EOF'
#!/bin/bash
# ソース編集前に最新テスト変更があるか検査
if [[ "$1" == *"write"* ]] && [[ "$2" == *".py"* ]]; then
  if ! git log --oneline -n 5 | grep -i "test"; then
    echo "ERROR: テストコードの変更が見つかりません" >&2
    exit 2
  fi
fi
EOF

# 2. 未使用コード検出 (post-tool)  
cat > .claude/hooks/post-tool/unused-detector.sh << 'EOF'
#!/bin/bash
# vulture で未使用コード検出
if command -v vulture >/dev/null; then
  if vulture . --min-confidence 80 | grep -v "__pycache__"; then
    echo "WARNING: 未使用コードが検出されました" >&2
  fi
fi
EOF

# 3. カバレッジチェック (stop)
cat > .claude/hooks/stop/coverage-check.sh << 'EOF'
#!/bin/bash
# 変更行未カバーなら exit 2
if command -v coverage >/dev/null; then
  coverage run -m pytest >/dev/null 2>&1
  if ! coverage report --show-missing | grep -q "100%"; then
    echo "ERROR: テストカバレッジが不足しています" >&2
    exit 2
  fi
fi
EOF

# 実行権限付与
chmod +x .claude/hooks/**/*.sh
```

**完了目安**: 実行権限付き shebang

### 1-5. GitHub Actions ワークフロー設定
**タスク**: `.github/workflows/claude.yml` を公式サンプルから作成

**手順**:
```bash
# ワークフローディレクトリ作成
mkdir -p .github/workflows

# Claude Code Action 設定
cat > .github/workflows/claude.yml << 'EOF'
name: Claude Code
on:
  issues:
    types: [opened, edited]
  issue_comment:
    types: [created, edited]
  pull_request:
    types: [opened, synchronize]

jobs:
  claude:
    runs-on: ubuntu-latest
    if: contains(github.event.comment.body, '@claude') || github.event_name == 'issues'
    steps:
      - uses: actions/checkout@v4
      - uses: anthropics/claude-code-action@v1
        with:
          claude-api-key: ${{ secrets.CLAUDE_API_KEY }}
          github-token: ${{ secrets.GITHUB_TOKEN }}
EOF
```

**完了目安**: Actions green

---

## ✅ 完了チェックリスト

### Day 0 確認項目
- [ ] リポジトリ戦略の文書化・チーム合意
- [ ] GitHub PAT・Claude API Key の発行
- [ ] GitHub Secrets への登録
- [ ] 開発環境要件の README 記載

### Day 1-2 確認項目
- [ ] GitHub リポジトリ作成・初期化
- [ ] README.md, CLAUDE.md 作成
- [ ] `.claude/settings.json` 設定
- [ ] Hook スクリプト 3 本作成・実行権限設定
- [ ] GitHub Actions ワークフロー設定・動作確認

### 動作テスト
```bash
# 設定確認
cat .claude/settings.json | jq .

# Hook テスト
.claude/hooks/pre-tool/tdd-guard.sh write test.py

# GitHub Actions 確認
gh workflow list
```

**次のステップ**: [ガバナンス設定](governance_setup.md)