# 📝 Issue テンプレート集

> **目的**: Claude Code に最適化された GitHub Issue テンプレートの提供

## 🎯 設計原則

### TDD 対応テンプレート
- **期待テスト必須** - 受け入れ基準をテストケース形式で記載
- **再現手順明確** - Claude が理解・実行可能な具体的手順
- **スコープ限定** - 1 Issue = 1 機能/1 バグ に制限

### Claude 実行最適化
- **構造化記述** - AI が解析しやすい明確な構造
- **サンプルコード** - 期待する入出力の具体例
- **制約の明示** - YAGNI・セキュリティ等の制約事項

## 📋 テンプレート一覧

### 1. 新機能開発テンプレート

```markdown
---
name: 新機能開発
about: TDD で新機能を実装します
title: "[FEATURE] 機能名"
labels: ["enhancement", "tdd"]
assignees: []
---

## 📝 機能概要
<!-- 実装したい機能の概要を簡潔に記述 -->

## 🎯 受け入れ基準
<!-- Claude が理解できるよう、明確な条件として記載 -->
- [ ] ユーザーは○○できる
- [ ] ○○の場合は△△になる
- [ ] エラー時は適切なメッセージを表示する

## 🧪 テストケース
<!-- TDD 実行のため、具体的なテストケースを記載 -->

### 正常系
1. **正常入力のテスト**
   - Input: `{"email": "user@example.com", "password": "valid123"}`
   - Expected: `{"success": true, "token": "jwt_token"}`

2. **境界値のテスト**
   - Input: `{"email": "a@b.co", "password": "12345678"}`
   - Expected: `{"success": true, "token": "jwt_token"}`

### 異常系
1. **無効入力のテスト**
   - Input: `{"email": "invalid", "password": "123"}`
   - Expected: `ValidationError: Invalid email format`

2. **空入力のテスト**
   - Input: `{"email": "", "password": ""}`
   - Expected: `ValidationError: Email and password required`

## 🏗️ 技術的制約
<!-- 実装時の制約・考慮事項 -->
- [ ] 既存の認証システムとの統合
- [ ] JWT トークンの使用
- [ ] パスワードのハッシュ化（bcrypt）
- [ ] レート制限の考慮

## 🚫 YAGNI 制約
<!-- 実装してはいけない機能の明示 -->
- OAuth 連携（将来の要件のため現在は不要）
- 多要素認証（現在の要求にない）
- パスワード履歴管理（要求されていない）

## 📚 参考資料
<!-- 関連する Issue・PR・ドキュメントのリンク -->
- 関連 Issue: #XXX
- 設計ドキュメント: docs/10_architecture/auth_design.md
- API 仕様: docs/api/auth_endpoints.md

## ✅ 完了条件
<!-- Claude の作業完了を判定する基準 -->
- [ ] 全テストケースが実装され、GREEN になる
- [ ] テストカバレッジ 100% を達成
- [ ] 未使用コード・関数が存在しない
- [ ] PR が作成され、CI が通る
```

### 2. バグ修正テンプレート

```markdown
---
name: バグ修正
about: 発見されたバグを TDD で修正します
title: "[BUG] バグの概要"
labels: ["bug", "tdd"]
assignees: []
---

## 🐛 バグの概要
<!-- バグの症状を簡潔に記述 -->

## 🔄 再現手順
<!-- Claude が同じバグを再現できるよう、具体的な手順を記載 -->
1. XXX ページにアクセス
2. フォームに以下を入力
   ```json
   {
     "email": "test@example.com",
     "amount": -100
   }
   ```
3. 送信ボタンをクリック

## 💥 実際の結果
<!-- 現在発生している問題の症状 -->
- エラーメッセージなしで処理が完了する
- データベースに負の値が保存される
- 後続処理でクラッシュが発生

## ✅ 期待される結果
<!-- 正しい動作の説明 -->
- バリデーションエラーが表示される
- データベースへの保存が拒否される
- ユーザーに適切なエラーメッセージを表示

## 🧪 再現テストケース
<!-- バグを捕捉するテストケース -->
```python
def test_negative_amount_validation():
    """負の金額でバリデーションエラーが発生することを確認"""
    with pytest.raises(ValidationError) as exc_info:
        process_payment(amount=-100)
    
    assert "Amount must be positive" in str(exc_info.value)

def test_negative_amount_not_saved():
    """負の金額がデータベースに保存されないことを確認"""
    initial_count = Payment.objects.count()
    
    try:
        process_payment(amount=-100)
    except ValidationError:
        pass
    
    assert Payment.objects.count() == initial_count
```

## 🔍 環境情報
- OS: Windows 10 / macOS 13.0 / Ubuntu 20.04
- ブラウザ: Chrome 120.0
- Python: 3.11.0
- Django: 4.2.0

## 📋 ログ・エラー出力
<!-- エラーログやスタックトレースがあれば記載 -->
```
Traceback (most recent call last):
  File "src/payments.py", line 45, in process_payment
    validate_amount(amount)
ValueError: Amount validation failed
```

## 🎯 修正方針
<!-- 修正の方向性（Claude の参考用） -->
- バリデーション関数の改善
- エラーハンドリングの追加
- ユーザーフィードバックの改善

## ✅ 修正完了条件
- [ ] 再現テストが FAILED から PASSED に変わる
- [ ] 既存のテストが全て PASSED を維持
- [ ] 類似バグの予防テストを追加
- [ ] 修正が最小限に留まっている
```

### 3. リファクタリングテンプレート

```markdown
---
name: リファクタリング
about: コード品質改善のためのリファクタリング
title: "[REFACTOR] 対象コンポーネント名"
labels: ["refactoring", "technical-debt"]
assignees: []
---

## 🔧 リファクタリング対象
<!-- 改善したいコード・モジュール -->
- ファイル: `src/services/user_service.py`
- 関数: `get_user_data()`, `update_user_profile()`
- 行数: 150-200 行程度

## 📊 現在の問題
<!-- コード品質の問題点 -->
- [ ] 循環的複雑度が高い（CC: 15）
- [ ] 関数が長すぎる（200行）
- [ ] 責務が混在している（DB・ビジネスロジック・バリデーション）
- [ ] テストが困難（モック箇所が多数）

## 🎯 改善目標
<!-- リファクタリング後の期待状態 -->
- [ ] 循環的複雑度を 10 以下に削減
- [ ] 関数を 50 行以下に分割
- [ ] 単一責任原則の適用
- [ ] テスタビリティの向上

## 🧪 リファクタリング前のテスト
<!-- 既存動作を保護するテスト -->
```python
def test_existing_behavior():
    """リファクタリング前の動作を保護するテスト"""
    user_data = get_user_data(user_id=1)
    assert user_data['name'] == 'John Doe'
    assert user_data['email'] == 'john@example.com'

def test_update_preserves_data():
    """更新処理の既存動作を保護"""
    result = update_user_profile(user_id=1, data={'name': 'Jane'})
    assert result.success == True
    assert User.objects.get(id=1).name == 'Jane'
```

## 🏗️ 提案する設計
<!-- リファクタリング後の設計案 -->
```python
# 分離後の構成案
class UserValidator:
    def validate_profile_data(self, data): ...

class UserRepository:
    def get_by_id(self, user_id): ...
    def update_profile(self, user_id, data): ...

class UserService:
    def __init__(self, validator, repository): ...
    def get_user_data(self, user_id): ...
    def update_user_profile(self, user_id, data): ...
```

## 🚫 制約事項
<!-- リファクタリング時の制約 -->
- [ ] 既存のAPIインターフェースは変更しない
- [ ] データベーススキーマは変更しない
- [ ] 外部ライブラリの追加は最小限に
- [ ] パフォーマンス劣化は許可しない

## ✅ 完了条件
- [ ] 全ての既存テストが PASSED を維持
- [ ] 循環的複雑度が目標値以下
- [ ] 関数の長さが目標値以下
- [ ] 新しい設計のユニットテストを追加
- [ ] コードレビューで品質改善を確認
```

## 🔧 カスタマイズガイド

### プロジェクト固有の調整

#### セキュリティ要件が高い場合
```markdown
## 🔒 セキュリティ考慮事項
- [ ] 入力サニタイゼーション
- [ ] SQLインジェクション対策
- [ ] XSS 対策
- [ ] 認証・認可の確認
```

#### パフォーマンス重視の場合
```markdown
## ⚡ パフォーマンス要件
- [ ] レスポンス時間: XXX ms 以下
- [ ] メモリ使用量: XXX MB 以下
- [ ] データベースクエリ数: XXX 回以下
```

#### マイクロサービス環境の場合
```markdown
## 🌐 サービス間連携
- [ ] API 互換性の維持
- [ ] 依存サービスの影響確認
- [ ] 分散トランザクションの考慮
```

## 📊 Issue 品質チェックリスト

### Claude 実行前の確認項目
- [ ] 受け入れ基準が明確に定義されている
- [ ] テストケースが具体的に記載されている
- [ ] 技術的制約が明示されている
- [ ] YAGNI 制約が適切に設定されている
- [ ] 完了条件が測定可能である

### Issue 作成者向けガイド
1. **1 Issue 1 タスク**: 複数の機能を混在させない
2. **具体的な例**: 抽象的な説明より具体例を重視
3. **テスト観点**: 実装者目線でなくテスト観点で記述
4. **制約の明示**: やってはいけないことを明確に記載

---

**活用指針**: これらのテンプレートを GitHub の Issue テンプレートとして設定し、プロジェクトの特性に応じてカスタマイズしてください。Claude による効率的な開発のため、詳細で構造化された Issue 作成を心がけてください。