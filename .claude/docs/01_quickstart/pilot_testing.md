# 🧪 パイロットテスト (Day 8-10)

> **目標**: 実際の開発タスクで Claude Code 環境を検証し、自動 PR 生成・Hook による品質管理を確認

## 📋 Day 8-10: パイロット実行 & フィードバック

### 5-1. サンプル Issue 作成
**タスク**: 新機能・バグ修正の Issue を 2 本起票

**手順**:

#### 新機能 Issue の作成
```markdown
# Issue テンプレート: 新機能

## 概要
ユーザー認証機能を追加する

## 受け入れ基準
- [ ] ユーザーはメールアドレス・パスワードでログインできる
- [ ] 無効な認証情報の場合はエラーメッセージを表示する  
- [ ] ログイン後はダッシュボードページに遷移する
- [ ] ログアウト機能が利用できる

## テストケース
1. **正常ログイン**
   - Input: 有効なメール・パスワード
   - Expected: ダッシュボードに遷移、認証トークン発行

2. **無効認証**
   - Input: 無効なメール・パスワード
   - Expected: エラーメッセージ表示、ログイン画面維持

3. **バリデーション**
   - Input: 空のメール・パスワード
   - Expected: バリデーションエラー表示

## 技術的制約
- JWT トークンを使用
- パスワードはハッシュ化して保存
- セッション管理は Redis を使用

## 関連 Issue
なし
```

#### バグ修正 Issue の作成
```markdown
# Issue テンプレート: バグ修正

## 問題の概要
商品検索で日本語キーワードが正しく動作しない

## 再現手順
1. 商品検索ページにアクセス
2. 検索フィールドに「東京」を入力
3. 検索ボタンをクリック

## 期待される結果
「東京」に関連する商品が表示される

## 実際の結果
「No results found」が表示される

## 環境
- OS: Windows 10
- ブラウザ: Chrome 120
- URL: https://example.com/search

## 追加情報
- 英語キーワード（"tokyo"）では正常に動作する
- 他の日本語キーワードでも同様の問題が発生

## ログ・スクリーンショット
```
Error in search API: UnicodeDecodeError at line 45
```
```

**完了目安**: Issue 上がる

### 5-2. 新機能開発の自動実行
**タスク**: `/project:new-feature proj_a#1` を実行し、Claude の自動開発を検証

**手順**:

#### Claude コマンド実行
```bash
# Issue コメントで Claude を呼び出し
# GitHub Issue #1 のコメント欄に以下を記載:

@claude /project:new-feature proj_a#1

このIssueの内容を確認して、テスト駆動で実装してください。
CLAUDE.md に記載されている TDD・YAGNI 原則を厳守してください。
```

#### 期待される Claude の動作確認
1. **①テスト作成**
   ```python
   # tests/test_auth.py (例)
   def test_valid_login():
       response = client.post('/auth/login', {
           'email': 'user@example.com',
           'password': 'password123'
       })
       assert response.status_code == 200
       assert 'token' in response.json()
   
   def test_invalid_login():
       response = client.post('/auth/login', {
           'email': 'user@example.com', 
           'password': 'wrong'
       })
       assert response.status_code == 401
       assert 'error' in response.json()
   ```

2. **②失敗確認**
   ```bash
   # Claude が実行するコマンド
   python -m pytest tests/test_auth.py -v
   # → FAILED (expected: 実装がないため失敗)
   ```

3. **③実装**
   ```python
   # src/auth.py (例)
   def login(email, password):
       user = authenticate_user(email, password)
       if user:
           return generate_token(user)
       else:
           raise AuthenticationError("Invalid credentials")
   ```

4. **④緑確認**
   ```bash
   python -m pytest tests/test_auth.py -v
   # → PASSED (all tests green)
   ```

5. **⑤PR生成**
   - コミットメッセージ: `feat: Add user authentication (#1)`
   - PR タイトル: `Add user authentication feature`
   - PR 説明: 実装内容・テスト結果・確認手順

**完了目安**: PR 作成

### 5-3. Hook による品質管理の確認
**タスク**: Hooks が適切に動作することを手動でトリガー・確認

**手順**:

#### A) テスト無し実装をブロック
```bash
# 意図的にテスト無しでコードを編集
cd projects/proj_a
echo "def new_function(): pass" >> src/main.py
git add src/main.py

# Hook が動作することを確認
.claude/hooks/pre-tool/tdd-guard.sh write src/main.py
# Expected: "ERROR: テストコードの変更が見つかりません"
```

#### B) 未使用コード検出で修正を促す
```bash
# 未使用関数を追加
echo "def unused_function(): return 'not used'" >> src/utils.py

# Hook による検出
.claude/hooks/post-tool/unused-detector.sh
# Expected: "WARNING: 未使用コードが検出されました"

# vulture による詳細確認
vulture . --min-confidence 80
# → src/utils.py:X: unused function 'unused_function'
```

#### Hook ログの確認
```bash
# Hook 実行ログを確認
cat .claude/logs/hook-execution.log

# 期待されるログ内容:
# [2024-01-15 10:30:00] PRE-TOOL: tdd-guard.sh blocked file write
# [2024-01-15 10:31:00] POST-TOOL: unused-detector.sh found 1 unused item
# [2024-01-15 10:32:00] STOP: coverage-check.sh failed (85% < 90%)
```

**完了目安**: Hook ログ

### 5-4. 人間レビュー・修正サイクル確認
**タスク**: PR に人間レビューを入れ、`@claude` で修正指示→自動更新を確認

**手順**:

#### 人間によるコードレビュー
```markdown
# PR コメント例

## 全体的な実装について
実装内容は要件を満たしていますが、以下の改善点があります。

### セキュリティ
- [ ] パスワードの複雑さチェックが不足
- [ ] ブルートフォース攻撃対策が必要

### エラーハンドリング  
- [ ] データベース接続エラーの処理を追加
- [ ] ログイン試行回数の制限

### テスト
- [ ] エッジケース (空文字、特殊文字) のテスト不足
- [ ] 統合テストの追加

@claude 
上記のレビュー指摘事項に対応してください。
特にセキュリティ面の改善を優先してください。
```

#### Claude による自動修正確認
Claude が以下の対応を行うことを確認:

1. **セキュリティ改善**
   ```python
   # パスワード複雑さチェック追加
   def validate_password_strength(password):
       if len(password) < 8:
           raise ValueError("Password too short")
       # 複雑さ要件チェック...
   
   # ブルートフォース対策
   def check_login_attempts(email):
       attempts = redis.get(f"login_attempts:{email}")
       if attempts and int(attempts) >= 5:
           raise TooManyAttemptsError()
   ```

2. **テスト追加**
   ```python
   def test_password_strength():
       with pytest.raises(ValueError):
           validate_password_strength("123")
   
   def test_brute_force_protection():
       # 5回失敗後のロック確認...
   ```

3. **自動コミット・PR更新**
   ```bash
   git commit -m "fix: Address security and error handling concerns"
   git push origin feat/authentication
   # → PR が自動更新される
   ```

**完了目安**: 差分反映

---

## 🔬 詳細な検証項目

### TDD サイクルの確認
```bash
# 各ステップの確認コマンド
git log --oneline | head -10
# → テスト→実装→リファクタのコミット履歴

git diff HEAD~3..HEAD~2  # テスト追加のコミット
git diff HEAD~2..HEAD~1  # 実装のコミット  
git diff HEAD~1..HEAD    # リファクタのコミット
```

### 品質メトリクスの確認
```bash
# カバレッジ確認
coverage run -m pytest && coverage report
# → 新規実装部分 100% カバレッジ

# 複雑度確認
radon cc src/ --show-complexity
# → 複雑度が適切な範囲内

# Lint 確認
flake8 src/ tests/
# → エラー・警告なし
```

### CI/CD パイプラインの確認
```bash
# GitHub Actions の実行確認
gh run list --workflow=claude.yml
gh run list --workflow=ci.yml

# 各ジョブの成功確認
gh run view <run-id> --log
```

---

## 🚨 トラブルシューティング

### よくある問題と対策

#### Claude が反応しない
```bash
# 原因確認
gh api repos/:owner/:repo/actions/secrets
# → CLAUDE_API_KEY の設定確認

# ログ確認
gh run view --log | grep ERROR
```

#### Hook エラー
```bash
# Hook 実行権限確認
ls -la .claude/hooks/**/*.sh
# → 実行権限 (-rwxr-xr-x) の確認

# Hook 構文確認
bash -n .claude/hooks/pre-tool/tdd-guard.sh
# → 構文エラーの確認
```

#### テストの失敗
```bash
# 依存関係確認
pip list | grep pytest
npm list | grep jest

# テスト環境確認
python -m pytest --version
npm run test -- --version
```

#### PR 作成失敗
```bash
# 権限確認
gh auth status
# → GitHub 権限の確認

# ブランチ状態確認
git status
git remote -v
```

---

## ✅ 完了チェックリスト

### Issue 作成・管理
- [ ] 新機能 Issue 作成 (受け入れ基準・テストケース含む)
- [ ] バグ修正 Issue 作成 (再現手順・期待結果含む)
- [ ] Issue テンプレートの活用

### Claude 自動開発
- [ ] `/project:new-feature` コマンド実行
- [ ] TDD サイクル (①テスト→②失敗→③実装→④緑→⑤PR) の確認
- [ ] YAGNI 原則の遵守確認
- [ ] 自動 PR 生成・適切なコミットメッセージ

### Hook 品質管理
- [ ] テスト無し実装のブロック確認
- [ ] 未使用コード検出・警告確認
- [ ] カバレッジ不足時の完了阻止確認
- [ ] Hook ログの記録・確認

### 人間-AI 協働
- [ ] 人間によるコードレビュー実施
- [ ] Claude による修正指示への対応確認
- [ ] 自動コミット・PR 更新の確認
- [ ] レビュー品質の評価

### 運用確認
- [ ] CI/CD パイプラインの正常動作
- [ ] メトリクス (カバレッジ・複雑度・Lint) の確認
- [ ] エラー時のロールバック手順確認

### 最終検証
```bash
# 環境全体の健全性確認
./scripts/health-check.sh

# 新人が 1 時間で環境構築できることの確認
time ./scripts/setup-new-developer.sh
# → 1 時間以内での完了

# 複数プロジェクトでの並行作業確認
cd projects/proj_a && /project:new-feature proj_a#2 &
cd projects/proj_b && /project:fix-bug proj_b#3 &
wait
```

## 🎉 パイロット完了・運用開始

上記の全ての確認が完了したら、**AI 駆動開発環境のパイロットテスト完了**です。

### 次のフェーズ
- **拡張機能の追加** (セキュリティスキャン・メトリクス可視化等)
- **複数チームでの運用開始**
- **Hook・テンプレートの継続改善**
- **運用メトリクスの収集・分析**

### 継続的改善
- 週次の振り返りでワークフローの最適化
- Hook・テンプレートの精度向上
- Claude との協働パターンの蓄積・共有

---

**おめでとうございます！** 🎊  
**迷わず再現・運用できる AI 駆動開発環境** の基盤が完成しました。