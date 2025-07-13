# 🔄 TDD ワークフロー実践ガイド

> **目的**: Claude Code を使ったテスト駆動開発（TDD）の具体的な実践方法

## 📋 TDD の基本サイクル

### Red-Green-Refactor サイクル
```
🔴 Red: テスト作成（失敗）
    ↓
🟢 Green: 最小実装（成功）
    ↓  
🔵 Refactor: 品質改善
    ↓
   繰り返し
```

## 🎯 Claude による TDD 実行

### Issue からの TDD 開始
```markdown
# Issue 記載例
## 受け入れ基準
- [ ] ユーザーはメールアドレスでログインできる
- [ ] 無効なメールの場合はエラーメッセージを表示する

## テストケース
1. **正常ログイン**: valid@example.com → 成功
2. **無効メール**: invalid-email → エラー
3. **空メール**: "" → バリデーションエラー
```

### Claude コマンド実行
```bash
# GitHub Issue コメントで実行
@claude /project:new-feature proj_a#123

このIssueの内容をテスト駆動で実装してください。
CLAUDE.md のTDD原則を厳守してください。
```

## 🔴 Phase 1: Red (テスト作成)

### Claude の自動テスト生成
Claude は以下の手順でテストを作成します：

```python
# tests/test_auth.py (例)
import pytest
from src.auth import login_user

def test_valid_email_login():
    """正常なメールアドレスでログインできること"""
    result = login_user("valid@example.com", "password123")
    assert result.success == True
    assert result.token is not None

def test_invalid_email_format():
    """無効なメール形式でエラーになること"""
    with pytest.raises(ValidationError):
        login_user("invalid-email", "password123")

def test_empty_email():
    """空のメールでバリデーションエラーになること"""
    with pytest.raises(ValidationError):
        login_user("", "password123")
```

### テスト失敗の確認
```bash
# Claude が実行するコマンド
python -m pytest tests/test_auth.py -v

# 期待される結果: FAILED (実装がないため)
tests/test_auth.py::test_valid_email_login FAILED
tests/test_auth.py::test_invalid_email_format FAILED  
tests/test_auth.py::test_empty_email FAILED
```

### TDD 制約の適用
- **実装コードは一切書かない** - テストのみ作成
- **モック・スタブは最小限** - 実際の動作をテスト
- **失敗することを確認** - Red 状態を必ず体験

## 🟢 Phase 2: Green (最小実装)

### Claude による最小実装
```python
# src/auth.py (例)
import re
from dataclasses import dataclass

@dataclass
class LoginResult:
    success: bool
    token: str = None

class ValidationError(Exception):
    pass

def login_user(email: str, password: str) -> LoginResult:
    """最小限の実装でテストを通す"""
    
    # 空メールチェック
    if not email:
        raise ValidationError("Email is required")
    
    # メール形式チェック  
    if not re.match(r'^[^@]+@[^@]+\.[^@]+$', email):
        raise ValidationError("Invalid email format")
    
    # 最小限の成功実装
    return LoginResult(success=True, token="dummy-token")
```

### テスト成功の確認
```bash
python -m pytest tests/test_auth.py -v

# 期待される結果: PASSED
tests/test_auth.py::test_valid_email_login PASSED
tests/test_auth.py::test_invalid_email_format PASSED
tests/test_auth.py::test_empty_email PASSED
```

### YAGNI 原則の適用
- **現在必要なもののみ実装** - 将来の拡張は考えない
- **テストを通す最小コード** - 余計な機能は追加しない
- **推測実装禁止** - 明確な要件のないコードは書かない

## 🔵 Phase 3: Refactor (品質改善)

### Claude による自動リファクタリング
```python
# リファクタリング後の src/auth.py
import re
from dataclasses import dataclass
from typing import Optional

@dataclass
class LoginResult:
    success: bool
    token: Optional[str] = None
    error_message: Optional[str] = None

class ValidationError(Exception):
    pass

def login_user(email: str, password: str) -> LoginResult:
    """ユーザーログイン処理"""
    
    try:
        _validate_email(email)
        token = _authenticate_user(email, password)
        return LoginResult(success=True, token=token)
    except ValidationError as e:
        return LoginResult(success=False, error_message=str(e))

def _validate_email(email: str) -> None:
    """メールアドレスのバリデーション"""
    if not email:
        raise ValidationError("Email is required")
    
    if not re.match(r'^[^@]+@[^@]+\.[^@]+$', email):
        raise ValidationError("Invalid email format")

def _authenticate_user(email: str, password: str) -> str:
    """ユーザー認証処理"""
    # 実際の認証ロジックは後で実装
    return "dummy-token"
```

### リファクタリングの原則
- **テストは変更しない** - 外部インターフェースを保持
- **単一責任原則** - 1つの関数は1つの責務のみ
- **DRY 原則** - 重複コードの排除
- **可読性向上** - 命名・構造の改善

## 🔧 Hook による TDD 強制

### PreToolUse Hook: TDD ガード
```bash
#!/bin/bash
# .claude/hooks/pre-tool/tdd-guard.sh

if [[ "$1" == *"write"* ]] && [[ "$2" == *".py"* ]]; then
  # 最近のコミットでテスト変更があるかチェック
  if ! git log --oneline -n 5 | grep -i "test"; then
    echo "ERROR: テストコードの変更が見つかりません" >&2
    echo "TDD原則に従い、実装前にテストを作成してください" >&2
    exit 2
  fi
fi
```

### PostToolUse Hook: 未使用コード検出
```bash
#!/bin/bash
# .claude/hooks/post-tool/unused-detector.sh

if command -v vulture >/dev/null; then
  unused=$(vulture . --min-confidence 80 2>/dev/null | grep -v "__pycache__")
  if [[ -n "$unused" ]]; then
    echo "WARNING: 未使用コードが検出されました" >&2
    echo "$unused" >&2
    echo "YAGNI原則に従い、不要なコードは削除してください" >&2
  fi
fi
```

### Stop Hook: カバレッジ確認
```bash
#!/bin/bash
# .claude/hooks/stop/coverage-check.sh

if command -v coverage >/dev/null; then
  coverage run -m pytest >/dev/null 2>&1
  coverage_percent=$(coverage report | tail -1 | grep -o '[0-9]*%' | head -1 | sed 's/%//')
  
  if [[ $coverage_percent -lt 90 ]]; then
    echo "ERROR: テストカバレッジが不足しています ($coverage_percent% < 90%)" >&2
    echo "新規コードのカバレッジを100%にしてください" >&2
    exit 2
  fi
fi
```

## 📊 TDD 品質メトリクス

### カバレッジ確認
```bash
# カバレッジレポート生成
coverage run -m pytest
coverage report --show-missing

# HTML レポート生成
coverage html
open htmlcov/index.html
```

### テスト品質チェック
```bash
# テスト実行時間確認
python -m pytest --durations=10

# テストの重複確認
python -m pytest --collect-only | grep "test_"
```

### 複雑度確認
```bash
# コード複雑度測定
radon cc src/ --show-complexity

# メンテナビリティ指数
radon mi src/
```

## 🚨 TDD アンチパターンと対策

### アンチパターン 1: テスト後付け
**問題**: 実装後にテストを書く
**対策**: Hook でブロック・Claude への明示指示

### アンチパターン 2: テスト改変
**問題**: 失敗テストを都合よく修正
**対策**: CLAUDE.md で「テスト変更禁止」を明記

### アンチパターン 3: 過度なモック
**問題**: 実装の詳細にモックが依存
**対策**: 外部インターフェースのみモック

### アンチパターン 4: 大きすぎるテスト
**問題**: 1つのテストで複数の関心事をテスト
**対策**: 単一責任でテストを分割

## 🔄 継続的改善

### TDD 効率化
- **テストテンプレート活用** - よくあるパターンの標準化
- **テストユーティリティ** - 共通処理の関数化
- **テストデータ管理** - Fixture・Factory の活用

### チーム標準化
- **テスト命名規則** - `test_[対象]_[条件]_[期待結果]`
- **アサーション規則** - 1テスト1アサーション推奨
- **テスト構造** - Given-When-Then パターン

---

**次のステップ**: [品質管理](quality_control.md) で Hook による自動品質管理を確認してください。