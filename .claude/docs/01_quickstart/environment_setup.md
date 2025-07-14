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

### 1-3.5. Hook システム依存ツールのインストール
**タスク**: vulture (Python 未使用コード検出) と pytest (テストフレームワーク) のインストール

> **重要**: このステップは継続改善システム（Phase 6）により強化されました。 
> Hook システムの完全動作に必要なツールを確実にインストールします。

**手順**:

#### Python 開発環境の準備
```bash
# Python 開発環境の確認
python3 --version  # Python 3.9+ が必要
pip3 --version     # pip の動作確認

# 仮想環境の作成（推奨）
python3 -m venv claude-workspace-env
source claude-workspace-env/bin/activate  # Linux/macOS
# claude-workspace-env\Scripts\activate   # Windows

# pip 最新化
pip install --upgrade pip
```

#### Hook 依存ツールのインストール
```bash
# IMP-001: vulture - Python 未使用コード検出ツール
pip install vulture

# IMP-002: pytest + pytest-cov - テストフレームワーク・カバレッジ
pip install pytest pytest-cov

# 追加品質ツール（推奨）
pip install ruff     # 高速 linter/formatter (Python)
pip install radon   # 複雑度測定

# インストール確認
vulture --version    # >= 2.7 を確認
pytest --version     # >= 7.0 を確認
coverage --version   # カバレッジ測定
ruff --version       # linter/formatter
```

#### システム全体設定ファイル作成
```bash
# 1. vulture 設定: ワークスペース全体用
cat > .vulture << 'EOF'
# vulture 設定: 未使用コード検出の除外設定
# Hook システム統合強化 (IMP-001 対応)

# プロジェクト構造除外
.claude/
governance/
projects/*/venv/
projects/*/node_modules/

# フレームワーク関数除外
**/models.py
**/views.py
**/settings.py
**/config.py

# テストファイル除外（ヘルパー関数等）
**/test_*.py
**/tests/
**/*_test.py
**/conftest.py

# VBA プロジェクト除外
pdi/

# 最小信頼度設定
--min-confidence 80
EOF

# 2. pytest 設定: ワークスペース全体用
cat > pytest.ini << 'EOF'
[tool:pytest]
# pytest 設定: Hook システム統合強化 (IMP-002 対応)

# テストディスカバリ
testpaths = 
    tests
    projects/*/tests
python_files = test_*.py *_test.py
python_classes = Test*
python_functions = test_*

# カバレッジ設定（Phase 6 継続改善対応）
addopts = 
    --strict-markers
    --strict-config
    --cov-report=term-missing
    --cov-report=html:htmlcov
    --cov-fail-under=60
    --verbose
    -ra

# テスト発見パターン
minversion = 7.0
markers =
    slow: marks tests as slow (deselect with '-m "not slow"')
    integration: marks tests as integration tests  
    unit: marks tests as unit tests
    hook: marks hook system tests
    
# 並列実行設定（オプション）
# addopts = -n auto  # pytest-xdist 使用時
EOF

# 3. プロジェクト別設定テンプレート
mkdir -p .claude/templates

cat > .claude/templates/project-vulture-config << 'EOF'
# プロジェクト固有 vulture 設定テンプレート
# 使用方法: cp .claude/templates/project-vulture-config projects/PROJECT_NAME/.vulture

# プロジェクト固有除外
# フレームワーク固有の未使用扱いパターン
src/PROJECT_NAME/migrations/
src/PROJECT_NAME/__init__.py

# 設定/定数ファイル
src/PROJECT_NAME/constants.py
src/PROJECT_NAME/enums.py

# 最小信頼度（プロジェクトに応じて調整）
--min-confidence 85
EOF

cat > .claude/templates/project-pytest-config << 'EOF'
# プロジェクト固有 pytest 設定テンプレート  
# 使用方法: cp .claude/templates/project-pytest-config projects/PROJECT_NAME/pytest.ini

[tool:pytest]
# プロジェクト固有テスト設定

testpaths = tests
python_files = test_*.py *_test.py

# プロジェクト固有カバレッジ
addopts = 
    --cov=src/PROJECT_NAME
    --cov-report=term-missing
    --cov-fail-under=80
    --verbose

markers =
    api: API tests
    db: database tests
    slow: slow running tests
EOF
```

#### 動作確認とトラブルシューティング
```bash
# 1. ツール動作確認
echo "def unused_function(): pass" > test_vulture.py
vulture test_vulture.py  # 未使用関数検出テスト
rm test_vulture.py

# 2. pytest 動作確認
mkdir -p test_temp/tests
echo "def test_sample(): assert True" > test_temp/tests/test_sample.py
cd test_temp && pytest --cov=. && cd ..
rm -rf test_temp

# 3. Hook 統合確認
.claude/hooks/post-tool/unused-detector.sh
.claude/hooks/stop/coverage-check.sh

# 4. トラブルシューティング用ヘルパー
cat > check_hook_deps.sh << 'EOF'
#!/bin/bash
# Hook 依存ツール確認スクリプト

echo "=== Hook 依存ツール動作確認 ==="

# vulture 確認
if command -v vulture >/dev/null 2>&1; then
    echo "✅ vulture: $(vulture --version)"
else
    echo "❌ vulture: 未インストール"
    echo "   解決方法: pip install vulture"
fi

# pytest 確認
if command -v pytest >/dev/null 2>&1; then
    echo "✅ pytest: $(pytest --version)"
else
    echo "❌ pytest: 未インストール" 
    echo "   解決方法: pip install pytest pytest-cov"
fi

# coverage 確認
if command -v coverage >/dev/null 2>&1; then
    echo "✅ coverage: $(coverage --version)"
else
    echo "❌ coverage: 未インストール"
    echo "   解決方法: pip install pytest-cov"
fi

echo ""
echo "=== Hook システム確認 ==="

# Hook 実行権限確認
for hook in .claude/hooks/*/*.sh; do
    if [[ -x "$hook" ]]; then
        echo "✅ $hook: 実行可能"
    else
        echo "❌ $hook: 実行権限なし"
        echo "   解決方法: chmod +x $hook"
    fi
done

echo ""
echo "=== 設定ファイル確認 ==="

# 設定ファイル存在確認
for config in .vulture pytest.ini .claude/templates/project-*-config; do
    if [[ -f "$config" ]]; then
        echo "✅ $config: 存在"
    else
        echo "❌ $config: 不足"
    fi
done
EOF

chmod +x check_hook_deps.sh
./check_hook_deps.sh
```

**完了目安**: 
- ✅ vulture, pytest, coverage コマンド実行可能
- ✅ .vulture, pytest.ini 設定ファイル作成
- ✅ プロジェクト別設定テンプレート準備済み
- ✅ Hook システムでツール不足警告が出ない
- ✅ check_hook_deps.sh での確認がすべて "✅" 

**Phase 6 継続改善対応**:
- IMP-001: vulture 統合強化により未使用コード検出機能完全動作
- IMP-002: pytest + pytest-cov 統合強化によりカバレッジチェック機能完全動作
- Hook 依存ツール確認スクリプトによる自動診断機能追加

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