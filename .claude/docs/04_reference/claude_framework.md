# 🤖 Claude Code フレームワーク詳細

> **目的**: Claude Code エージェントの動作原理・ライフサイクル・技術仕様の詳細解説

## 🔄 Claude Code ライフサイクル

### 基本動作サイクル
```
Context (コンテクスト)
    ↓
Tools (ツール)
    ↓
Permission Control (権限制御)
    ↓
Execution (実行)
    ↓
Feedback (フィードバック)
    ↓
[サイクル継続 or 完了]
```

## 📋 Phase 1: Context (コンテクスト)

### コンテクスト構成要素
Claude は以下の情報を統合してコンテクストを構築します：

#### 1. GitHub Issue コンテンツ
```markdown
# Issue例
## 概要
ユーザー認証機能を追加

## 受け入れ基準
- [ ] メールアドレス・パスワードでログイン
- [ ] 無効認証時のエラー表示
- [ ] ログイン後のダッシュボード遷移

## テストケース
1. 正常ログイン: valid@example.com → 成功
2. 無効認証: wrong@example.com → エラー
```

#### 2. CLAUDE.md (プロジェクト憲法)
```markdown
# プロジェクト憲法

## 開発原則
- **TDD**: 実装前にテスト作成を徹底
- **YAGNI**: 現在必要な機能のみ実装
- **KISS**: シンプルな設計を維持

## 禁止事項
- テストコードの改変
- 推測による機能実装
- 過度な汎用化・抽象化
```

#### 3. 既存コードベース
```python
# 既存コード例 - Claude が参照する
class UserService:
    def get_user(self, user_id: int) -> User:
        """既存のユーザー取得メソッド"""
        pass
    
    # 新機能はこのパターンに従って実装
```

#### 4. プロジェクト設定
```json
// .claude/settings.json
{
  "allowedTools": ["python", "pytest", "git"],
  "codeStyle": "google",
  "testFramework": "pytest",
  "lintConfig": "flake8"
}
```

### コンテクスト優先度
1. **CLAUDE.md** (最高優先度) - システムルール
2. **GitHub Issue** - 具体的要求仕様
3. **既存コード** - 実装パターン・規約
4. **ユーザープロンプト** - 追加指示・制約

## 🔧 Phase 2: Tools (ツール)

### 利用可能ツールカテゴリ

#### ファイル操作ツール
```yaml
tools:
  - name: "read"
    purpose: "ファイル内容の読み取り"
    usage: "既存コード・設定の確認"
  
  - name: "write" 
    purpose: "新規ファイル作成"
    usage: "テストコード・実装の作成"
  
  - name: "edit"
    purpose: "既存ファイル編集"
    usage: "機能追加・バグ修正"
```

#### 実行ツール
```yaml
tools:
  - name: "bash"
    purpose: "シェルコマンド実行"
    usage: "テスト実行・Lint・ビルド"
  
  - name: "python"
    purpose: "Python スクリプト実行"
    usage: "テスト・検証スクリプト"
```

#### Git 操作ツール
```yaml
tools:
  - name: "git"
    purpose: "バージョン管理操作"
    usage: "コミット・ブランチ・PR作成"
```

### ツール実行パターン

#### TDD サイクルでのツール使用
```
1. read    → 既存テスト・実装の確認
2. write   → 新規テストファイル作成
3. bash    → pytest 実行 (失敗確認)
4. edit    → 実装コード追加
5. bash    → pytest 実行 (成功確認)
6. git     → コミット・PR作成
```

#### 品質チェックでのツール使用
```
1. bash    → coverage run -m pytest
2. bash    → coverage report
3. bash    → vulture . (未使用コード検出)
4. bash    → radon cc src/ (複雑度測定)
```

## 🔒 Phase 3: Permission Control (権限制御)

### 許可システム階層

#### 1. allowedTools による基本許可
```json
{
  "allowedTools": [
    "read",      // ファイル読み取り
    "write",     // ファイル作成  
    "edit",      // ファイル編集
    "bash:pytest",  // テスト実行
    "bash:git",     // Git操作
    "python"     // Python実行
  ]
}
```

#### 2. Hook による動的制御
Hook システムは allowedTools より強い制御力を持ちます：

```bash
# PreToolUse Hook 例
if [[ "$TOOL" == "write" ]] && [[ "$FILE" == *.py ]]; then
  if ! recent_test_changes; then
    echo "ERROR: テスト無し実装は禁止"
    exit 2  # ツール実行をブロック
  fi
fi
```

### Hook の実行タイミング

#### PreToolUse Hook
```
Claude の思考
    ↓
ツール選択・引数決定
    ↓
PreToolUse Hook 実行 ← ここで事前チェック
    ↓
(Hook が exit 2 → ツール実行キャンセル)
    ↓
ツール実行
```

#### PostToolUse Hook
```
ツール実行
    ↓
実行結果取得
    ↓
PostToolUse Hook 実行 ← ここで結果検証
    ↓
(Hook が追加処理・警告出力)
    ↓
Claude への結果フィードバック
```

#### Stop Hook
```
Claude のタスク完了判断
    ↓
Stop Hook 実行 ← ここで完了条件チェック
    ↓
(Hook が exit 2 → 完了ブロック・継続強制)
    ↓
最終応答出力
```

## ⚙️ Phase 4: Execution (実行)

### 実行環境
Claude Code は以下の環境でツールを実行します：

#### シェル環境
```bash
# 実行環境の特徴
- Working Directory: プロジェクトルート
- Shell: bash (Linux/macOS) or PowerShell (Windows)
- Environment Variables: GitHub Actions secrets
- PATH: システム標準 + プロジェクト固有
```

#### ファイルシステムアクセス
```
Permission Scope:
├── プロジェクトルート/ (読み書き可能)
│   ├── src/
│   ├── tests/
│   ├── .claude/
│   └── .git/
├── $HOME/ (制限付き読み取り)
└── /system/ (アクセス不可)
```

### 実行ログとフィードバック

#### ツール実行ログ
```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "tool": "bash",
  "command": "python -m pytest tests/test_auth.py",
  "exit_code": 0,
  "stdout": "tests/test_auth.py::test_login PASSED",
  "stderr": "",
  "duration_ms": 1250
}
```

#### Hook実行ログ
```json
{
  "timestamp": "2024-01-15T10:29:55Z", 
  "hook_type": "pre-tool",
  "hook_name": "tdd-guard",
  "tool_blocked": "write",
  "reason": "No recent test changes found",
  "exit_code": 2
}
```

## 🔄 Phase 5: Feedback (フィードバック)

### フィードバック情報源

#### 1. ツール実行結果
```python
# pytest 実行結果の解析例
"""
tests/test_auth.py::test_valid_login PASSED
tests/test_auth.py::test_invalid_email FAILED
tests/test_auth.py::test_empty_password PASSED

FAILURES:
test_invalid_email: ValidationError not raised
"""
```

Claude はこの結果から：
- 1つのテストが失敗していることを認識
- ValidationError が期待通り発生していないと判断
- 該当実装の修正が必要と理解

#### 2. Hook からのフィードバック
```bash
# Hook からの構造化フィードバック例
{
  "status": "warning",
  "type": "unused_code",
  "details": {
    "unused_functions": ["helper_function"],
    "unused_variables": ["temp_var"],
    "suggestions": ["Remove unused code or add tests"]
  }
}
```

Claude はこのフィードバックを受けて：
- 未使用コードの存在を認識
- 削除またはテスト追加の判断を実行
- YAGNI原則に従った自動修正を実施

#### 3. エラー・例外情報
```python
# エラー情報の構造化
{
  "error_type": "ImportError",
  "message": "No module named 'src.auth'",
  "file": "tests/test_auth.py",
  "line": 3,
  "suggestion": "Check module path or create missing file"
}
```

### フィードバックループの自動化

#### 収束型フィードバック
```
実装 → テスト実行 → 失敗 → 修正 → テスト実行 → 成功
  ↑                                              ↓
  └──────── 成功まで自動反復 ←─────────────────────┘
```

#### 発散防止メカニズム
```python
# 無限ループ防止の制約
MAX_ITERATIONS = 10
TIMEOUT_MINUTES = 30

# 品質ゲートによる強制終了
if coverage < 90%:
    Stop Hook が exit 2 → タスク継続強制
    
if unused_code_detected:
    PostToolUse Hook が警告 → 削除またはテスト追加促進
```

## 🧠 Claude の思考プロセス

### 内部推論ステップ
1. **問題理解** - Issue・CLAUDE.md の統合解釈
2. **解決戦略** - TDD・YAGNI に基づく実装計画
3. **ツール選択** - 適切なツール・引数の決定
4. **実行監視** - Hook・エラーへの対応
5. **品質確認** - 完了条件の自動チェック

### 学習・適応メカニズム
- **パターン認識** - 既存コードの実装パターン学習
- **エラー対応** - 同種エラーの回避策記憶
- **品質基準** - プロジェクト固有の品質要件理解
- **Hook 適応** - Hook フィードバックからの行動修正

## 🔧 高度な制御機能

### 条件付きツール実行
```json
{
  "conditionalTools": {
    "bash:rm": {
      "condition": "user_approval_required",
      "allowedPaths": ["temp/*", "cache/*"]
    },
    "bash:curl": {
      "condition": "network_access_approved",
      "allowedHosts": ["api.github.com"]
    }
  }
}
```

### 並行実行制御
```yaml
concurrency:
  max_parallel_tools: 3
  tool_timeout: "5m"
  resource_limits:
    memory: "1GB"
    cpu: "2 cores"
```

### セキュリティ境界
```bash
# 実行サンドボックス
- ファイルシステム: プロジェクト内限定
- ネットワーク: 許可リスト制
- プロセス: 子プロセス生成制限
- リソース: CPU・メモリ制限
```

---

**活用指針**: このフレームワーク理解を基に、プロジェクト固有の設定・Hook・制約を設計し、Claude Code を効果的に制御してください。