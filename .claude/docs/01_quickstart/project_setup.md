# 📦 プロジェクト設定 (Day 5-6)

> **目標**: 既存プロジェクトの git worktree 統合と個別プロジェクトの設定管理

## 📋 Day 5-6: Project レイヤ移行準備

### 3-1. 既存プロジェクトの worktree 配置
**タスク**: 既存プロジェクト `proj_a.git` を worktree で `projects/proj_a` に配置

**手順**:
```bash
# 1. 既存プロジェクトをリモートとして追加
git remote add proj_a https://github.com/your-org/proj_a.git
git fetch proj_a

# 2. worktree として配置
git worktree add projects/proj_a proj_a/main

# 3. worktree の設定確認
cd projects/proj_a
git remote set-url origin https://github.com/your-org/proj_a.git
git status
```

**worktree 配置の確認**:
```bash
# worktree 一覧表示
git worktree list

# 期待される出力例:
# /path/to/workspace                    main
# /path/to/workspace/projects/proj_a    proj_a/main
```

**完了目安**: 配置確認・リモート URL 設定

### 複数プロジェクトの場合
```bash
# 追加プロジェクトの配置
git remote add proj_b https://github.com/your-org/proj_b.git
git fetch proj_b
git worktree add projects/proj_b proj_b/main

# リモート設定
cd projects/proj_b
git remote set-url origin https://github.com/your-org/proj_b.git
```

### 3-2. プロジェクト固有 Hook 設定
**タスク**: `projects/proj_a/.claude/hooks_local/` に プロジェクト固有テスト実行スクリプトを配置

**手順**:
```bash
# プロジェクト固有の Claude 設定
cd projects/proj_a
mkdir -p .claude/hooks_local

# プロジェクト固有のテスト実行 Hook
cat > .claude/hooks_local/test-runner.sh << 'EOF'
#!/bin/bash
# プロジェクト固有のテスト実行スクリプト

PROJECT_TYPE=$(basename "$PWD")

case "$PROJECT_TYPE" in
  "python-api")
    # Python プロジェクトの場合
    python -m pytest tests/ --cov=src --cov-report=term-missing
    ;;
  "node-app") 
    # Node.js プロジェクトの場合
    npm test -- --coverage --verbose
    ;;
  "go-service")
    # Go プロジェクトの場合  
    go test ./... -cover -v
    ;;
  *)
    # デフォルト: 汎用テストコマンド
    if [ -f package.json ]; then
      npm test
    elif [ -f requirements.txt ]; then
      python -m pytest
    elif [ -f go.mod ]; then
      go test ./...
    else
      echo "Unknown project type: $PROJECT_TYPE"
      exit 1
    fi
    ;;
esac
EOF

chmod +x .claude/hooks_local/test-runner.sh
```

**Hook の継承設定**:
```bash
# プロジェクト固有の settings.json (Workspace を継承)
cat > .claude/settings.json << 'EOF'
{
  "extends": "../../.claude/settings.json",
  "allowedTools": [
    "npm",
    "python", 
    "go",
    "docker"
  ],
  "hookPaths": [
    "../../../.claude/hooks",
    "./hooks_local"
  ]
}
EOF
```

**完了目安**: 差分最小での Hook 設定

### 3-3. Dev Container 設定
**タスク**: `projects/proj_a/docs/20_environment/container_setup.md` に設定を記載

**手順**:
```bash
# ドキュメントディレクトリ作成
cd projects/proj_a
mkdir -p docs/20_environment

# Dev Container 設定ドキュメント
cat > docs/20_environment/container_setup.md << 'EOF'
# Dev Container セットアップ

## 設定ファイル

### .devcontainer/devcontainer.json
```json
{
  "name": "Project A Development",
  "build": {
    "dockerfile": "Dockerfile"
  },
  "features": {
    "ghcr.io/devcontainers/features/git:1": {},
    "ghcr.io/devcontainers/features/claude-code:1": {}
  },
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-python.python",
        "ms-vscode.vscode-typescript-next",
        "anthropics.claude-code"
      ],
      "settings": {
        "python.defaultInterpreterPath": "/usr/local/bin/python"
      }
    }
  },
  "forwardPorts": [3000, 8000],
  "postCreateCommand": "npm install && pip install -r requirements.txt"
}
```

### .devcontainer/Dockerfile
```dockerfile
FROM mcr.microsoft.com/devcontainers/python:3.11

# Node.js インストール
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
RUN sudo apt-get install -y nodejs

# プロジェクト依存関係
COPY requirements.txt package.json ./
RUN pip install -r requirements.txt
RUN npm install

# Claude Code CLI
RUN npm install -g @anthropics/claude-code
```

## Docker Compose 統合

### docker-compose.yml
```yaml
version: '3.8'
services:
  app:
    build:
      context: .
      dockerfile: .devcontainer/Dockerfile
    volumes:
      - .:/workspace
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - CLAUDE_API_KEY=${CLAUDE_API_KEY}
    ports:
      - "3000:3000"
      - "8000:8000"
  
  db:
    image: postgres:13
    environment:
      POSTGRES_DB: proj_a_dev
      POSTGRES_USER: developer
      POSTGRES_PASSWORD: password
    ports:
      - "5432:5432"
```

## 起動手順

```bash
# 1. Dev Container で開く (VS Code)
code --folder-uri vscode-remote://dev-container+<hash>/workspace

# 2. または Docker Compose で起動
docker-compose up -d

# 3. 依存関係インストール確認
npm test
python -m pytest
```
EOF

# 実際の .devcontainer 設定ファイル作成
mkdir -p .devcontainer

cat > .devcontainer/devcontainer.json << 'EOF'
{
  "name": "Project A Development",
  "build": {
    "dockerfile": "Dockerfile"
  },
  "customizations": {
    "vscode": {
      "extensions": [
        "anthropics.claude-code"
      ]
    }
  }
}
EOF
```

**完了目安**: 編集完了・Dev Container 動作確認

### 3-4. CI 統合・衝突回避
**タスク**: 既存 CI を `proj_a` 側に残し、Workspace CI と衝突しないよう設定

**手順**:
```bash
# プロジェクト固有 CI ワークフロー確認
cd projects/proj_a
ls .github/workflows/

# 既存の CI にプレフィックス追加
cat > .github/workflows/ci.yml << 'EOF'
name: Project A - CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  proj-a-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
      
      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      
      - name: Install dependencies
        run: |
          npm install
          pip install -r requirements.txt
      
      - name: Run tests
        run: |
          npm test
          python -m pytest tests/
      
      - name: Code quality checks
        run: |
          npm run lint
          python -m flake8 src/

  proj-a-build:
    needs: proj-a-test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build application
        run: |
          npm run build
          python setup.py sdist
EOF
```

**衝突回避の確認**:
```bash
# Workspace レベルの CI
cat ../../.github/workflows/claude.yml | grep "name:"
# → "Claude Code"

# プロジェクト レベルの CI  
cat .github/workflows/ci.yml | grep "name:"
# → "Project A - CI"

# ジョブ名の重複確認
gh workflow list --repo your-org/workspace
gh workflow list --repo your-org/proj_a
```

**完了目安**: 両方 green で動作

---

## 🔧 高度な設定

### プロジェクト間の依存関係管理
```bash
# monorepo-tools の設定
cat > package.json << 'EOF'
{
  "name": "workspace",
  "workspaces": [
    "projects/*"
  ],
  "scripts": {
    "test:all": "npm run test --workspaces",
    "build:all": "npm run build --workspaces"
  }
}
EOF
```

### 統合テストの設定
```bash
# 統合テスト用の compose
cat > docker-compose.integration.yml << 'EOF'
version: '3.8'
services:
  proj-a:
    build: ./projects/proj_a
    environment:
      - NODE_ENV=test
  
  proj-b:
    build: ./projects/proj_b
    depends_on:
      - proj-a
    environment:
      - API_URL=http://proj-a:3000
  
  integration-tests:
    build:
      context: .
      dockerfile: tests/Dockerfile
    depends_on:
      - proj-a
      - proj-b
    command: npm run test:integration
EOF
```

### VS Code Workspace 設定
```bash
# Multi-root workspace 設定
cat > workspace.code-workspace << 'EOF'
{
  "folders": [
    {
      "name": "Workspace Root",
      "path": "."
    },
    {
      "name": "Project A",
      "path": "./projects/proj_a"
    },
    {
      "name": "Project B", 
      "path": "./projects/proj_b"
    }
  ],
  "settings": {
    "claude-code.workspaceMode": "multi-project"
  },
  "extensions": {
    "recommendations": [
      "anthropics.claude-code"
    ]
  }
}
EOF
```

---

## ✅ 完了チェックリスト

### worktree 設定
- [ ] 既存プロジェクトのリモート追加・fetch
- [ ] `git worktree add projects/proj_a` 実行
- [ ] リモート URL の再設定
- [ ] worktree 配置の確認

### プロジェクト固有設定
- [ ] `.claude/hooks_local/` ディレクトリ作成
- [ ] プロジェクト固有テスト実行スクリプト作成  
- [ ] Hook 継承設定 (settings.json)
- [ ] 実行権限・shebang 確認

### Dev Container 
- [ ] `docs/20_environment/container_setup.md` 作成
- [ ] `.devcontainer/` 設定ファイル作成
- [ ] docker-compose.yml 準備
- [ ] Dev Container 起動テスト

### CI 統合
- [ ] 既存 CI ワークフローの確認
- [ ] ジョブ名プレフィックス追加
- [ ] Workspace CI との衝突回避確認
- [ ] 両方の CI が green で動作

### 動作テスト
```bash
# worktree 状態確認
git worktree list

# プロジェクト固有 Hook テスト
cd projects/proj_a
.claude/hooks_local/test-runner.sh

# CI 状態確認  
gh workflow list
gh run list --workflow=ci.yml

# Dev Container テスト
code --folder-uri vscode-remote://dev-container+<hash>/workspace
```

**次のステップ**: [テンプレート設定](template_setup.md)