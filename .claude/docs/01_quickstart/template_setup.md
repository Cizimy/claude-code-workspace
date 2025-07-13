# 🧩 テンプレート設定 (Day 7)

> **目標**: Claude コマンド・テンプレートを整備し、AI 自動化の準備を完了

## 📋 Day 7: Claude コマンドテンプレート整備

### 4-1. 新機能開発テンプレート
**タスク**: `.claude/commands/project:new-feature` で 10 step TDD テンプレを YAML で保存

**手順**:
```bash
# コマンドディレクトリ確認
ls .claude/commands/

# 新機能開発テンプレート作成
cat > .claude/commands/project:new-feature << 'EOF'
name: "新機能開発 (TDD)"
description: "テスト駆動開発で新機能を実装します"

usage: |
  /project:new-feature <project_name>#<issue_number>
  
  例: /project:new-feature proj_a#123

parameters:
  - name: project_name
    description: "プロジェクト名 (projects/ 配下のディレクトリ名)"
    required: true
  - name: issue_number
    description: "GitHub Issue 番号"
    required: true

steps:
  1:
    title: "要件分析"
    description: "Issue の内容を読み込み、実装要件を明確化します"
    actions:
      - "GitHub Issue の詳細を取得・分析"
      - "受け入れ基準の確認・質問提起"
      - "技術的制約・依存関係の確認"
    
  2:
    title: "実装計画"
    description: "KISS・YAGNI 原則に基づいてシンプルな設計を提案します"
    actions:
      - "最小限の設計を提案 (過度な汎用化を避ける)"
      - "既存コードとの整合性確認"
      - "関心の分離 (UI vs ロジック vs データ) を適用"

  3:
    title: "テスト作成 (Red)"
    description: "実装前に失敗するテストケースを作成します"
    actions:
      - "期待する挙動のテストケース作成"
      - "エッジケースのテストケース追加"  
      - "テスト実行で失敗することを確認"
    constraints:
      - "実装コードは書かない (テストのみ)"
      - "モック・スタブは最小限に留める"

  4:
    title: "失敗確認 (Red)"
    description: "新しいテストが適切に失敗することを確認します"
    actions:
      - "テストスイート実行"
      - "新規テストが期待通り失敗することを確認"
      - "既存テストに影響がないことを確認"
    exit_condition: "テストが失敗しない場合は Step 3 に戻る"

  5:
    title: "最小実装 (Green)"
    description: "テストを通すための最小限のコードを実装します"
    actions:
      - "失敗するテストを通すための最小コード実装"
      - "YAGNI 原則の厳格な適用 (現在必要なもののみ)"
      - "複雑な設計・汎用化は避ける"
    constraints:
      - "テストで要求されていない機能は実装しない"
      - "将来の拡張を見越した実装は禁止"

  6:
    title: "テスト実行 (Green確認)"
    description: "全てのテストが通ることを確認します"
    actions:
      - "テストスイート実行"
      - "新規・既存テスト全てがパスすることを確認"
      - "失敗がある場合は Step 5 に戻って修正"
    exit_condition: "全テストが緑になるまで継続"

  7:
    title: "リファクタリング"
    description: "テストを保持したままコードの品質を改善します"
    actions:
      - "単一責任原則の適用確認"
      - "重複コードの排除 (DRY)"
      - "命名・構造の改善"
    constraints:
      - "テストは変更しない"
      - "外部インターフェースは変更しない"

  8:
    title: "未使用コード確認"
    description: "実装した機能に未使用要素がないか確認します"
    actions:
      - "静的解析による未使用関数・変数の検出"
      - "不要なコードの削除"
      - "または該当機能のテスト追加"

  9:
    title: "ドキュメント更新"
    description: "必要に応じてドキュメントを更新します"
    actions:
      - "API ドキュメントの更新"
      - "README の使用例追加"
      - "設定変更がある場合の手順書更新"

  10:
    title: "コミット・PR作成"
    description: "変更をコミットし、Pull Request を作成します"
    actions:
      - "意味のあるコミットメッセージでコミット"
      - "Issue 番号を含むコミットメッセージ"
      - "PR 作成・テンプレート埋め込み"

hooks:
  pre_step:
    - "Hook: TDD ガード (テスト無し実装の防止)"
  post_step:
    - "Hook: 未使用コード検出"
    - "Hook: カバレッジチェック"
  on_completion:
    - "Hook: 全テスト実行・品質確認"

quality_gates:
  - "全てのテストがパス"
  - "新規コードのカバレッジ 100%"
  - "未使用コード・関数なし"
  - "Lint エラーなし"
EOF
```

**完了目安**: コマンド登録

### 4-2. バグ修正テンプレート
**タスク**: `.claude/commands/project:fix-bug` で再現テスト→修正サイクルテンプレ作成

**手順**:
```bash
cat > .claude/commands/project:fix-bug << 'EOF'
name: "バグ修正 (TDD)"
description: "テスト駆動でバグを修正します"

usage: |
  /project:fix-bug <project_name>#<issue_number>
  
  例: /project:fix-bug proj_a#456

parameters:
  - name: project_name
    description: "プロジェクト名"
    required: true
  - name: issue_number
    description: "バグ報告 Issue 番号"
    required: true

steps:
  1:
    title: "バグ再現"
    description: "報告されたバグを再現するテストを作成します"
    actions:
      - "Issue からバグの症状・再現手順を確認"
      - "バグを再現するテストケース作成"
      - "期待値と実際の結果の差を明確化"

  2:
    title: "再現確認"
    description: "作成したテストでバグが再現されることを確認します"
    actions:
      - "再現テスト実行"
      - "テストが失敗 (バグを捉えている) ことを確認"
      - "既存テストに影響がないことを確認"

  3:
    title: "原因特定"
    description: "バグの根本原因を特定します"
    actions:
      - "スタックトレース・ログの分析"
      - "コードベース内の該当箇所特定"
      - "影響範囲の調査"

  4:
    title: "修正実装"
    description: "バグを修正するコードを実装します"
    actions:
      - "根本原因に対する最小限の修正"
      - "副作用・他機能への影響を最小化"
      - "防御的プログラミングの適用"
    constraints:
      - "修正は最小限に留める"
      - "新機能の追加は行わない"

  5:
    title: "修正確認"
    description: "バグ修正により全てのテストが通ることを確認します"
    actions:
      - "再現テストが成功することを確認"
      - "既存テストが全て通ることを確認"
      - "回帰テストの実施"

  6:
    title: "追加テスト"
    description: "類似バグの予防テストを追加します"
    actions:
      - "エッジケースの追加テスト作成"
      - "同種のバグを防ぐテストケース追加"
      - "境界値テストの確認"

  7:
    title: "コードクリーンアップ"
    description: "修正により生じた技術的負債を解消します"
    actions:
      - "修正箇所のリファクタリング"
      - "コメント・ドキュメントの更新"
      - "コーディング規約への準拠確認"

  8:
    title: "コミット・PR"
    description: "修正をコミットし、Pull Request を作成します"
    actions:
      - 'Fix #<issue_number>: <修正概要> 形式でコミット'
      - "修正内容・影響範囲を PR に記載"
      - "テスト結果・検証手順の添付"

validation:
  - "再現テストが成功に変わる"
  - "既存テストが全て通る"
  - "修正が最小限である"
  - "副作用が発生していない"
EOF
```

**完了目安**: 同上

### 4-3. コマンド早見表の作成
**タスク**: `docs/30_ai_workflow/commands.md` に早見表を追加

**手順**:
```bash
# AI ワークフローディレクトリ作成
mkdir -p docs/30_ai_workflow

cat > docs/30_ai_workflow/commands.md << 'EOF'
# Claude Commands 早見表

## 🚀 基本コマンド

### /project:new-feature
**用途**: 新機能の TDD 実装  
**構文**: `/project:new-feature <project>#<issue>`  
**例**: `/project:new-feature proj_a#123`

**実行ステップ**:
1. 要件分析 → 2. 実装計画 → 3. テスト作成 → 4. 失敗確認 → 5. 最小実装
6. テスト確認 → 7. リファクタ → 8. 未使用確認 → 9. ドキュメント → 10. PR作成

### /project:fix-bug  
**用途**: バグの TDD 修正  
**構文**: `/project:fix-bug <project>#<issue>`  
**例**: `/project:fix-bug proj_a#456`

**実行ステップ**:
1. バグ再現 → 2. 再現確認 → 3. 原因特定 → 4. 修正実装
5. 修正確認 → 6. 追加テスト → 7. クリーンアップ → 8. PR作成

## 🔧 高度なコマンド

### /workspace:security-review
**用途**: 全プロジェクトのセキュリティスキャン  
**構文**: `/workspace:security-review [--severity=high]`

### /workspace:dependency-update  
**用途**: 依存関係の一括更新・脆弱性チェック  
**構文**: `/workspace:dependency-update [--project=all]`

### /project:performance-test
**用途**: パフォーマンステストの実行・分析  
**構文**: `/project:performance-test <project> [--baseline=main]`

## 📊 分析・レポートコマンド

### /workspace:metrics
**用途**: 全プロジェクトのメトリクス取得  
**出力**: カバレッジ・複雑度・技術的負債レポート

### /project:health-check
**用途**: プロジェクトの健全性チェック  
**確認項目**: テスト・Lint・セキュリティ・パフォーマンス

## 🎯 使用パターン

### 新機能開発の流れ
```
1. GitHub で Issue 作成
2. Issue に受け入れ基準・テストケースを記載
3. `/project:new-feature proj_a#123` 実行
4. Claude が TDD サイクルを自動実行
5. 生成された PR をレビュー・マージ
```

### バグ修正の流れ
```
1. バグ報告 Issue 作成 (再現手順含む)
2. `/project:fix-bug proj_a#456` 実行  
3. Claude がバグ再現→修正→検証を自動実行
4. 修正 PR をレビュー・マージ
```

### 品質管理の流れ
```
週次: /workspace:metrics でメトリクス確認
月次: /workspace:security-review で脆弱性確認  
リリース前: /project:health-check で最終確認
```

## ⚠️ 制約・注意事項

### TDD 制約
- **テスト先行**: 実装前に必ずテスト作成
- **最小実装**: テストを通すための最小限のコード
- **リファクタ**: テスト保持したまま品質改善

### YAGNI 制約  
- **現在必要なもののみ**: 将来の拡張を見越した実装禁止
- **過度な汎用化禁止**: 1回しか使わない機能の共通化不可
- **推測実装禁止**: 明確な要件のない機能実装不可

### Hook による制御
- **未使用コード**: 自動検出・削除要請
- **テスト無し実装**: Hook でブロック
- **カバレッジ不足**: 完了を阻止

## 🔗 関連ドキュメント

- **[Hook 詳細](hooks.md)** - 品質ガードの仕組み
- **[設定](allowed_tools.md)** - 許可ツール・権限管理
- **[運用ガイド](../03_operations/)** - 日常運用でのベストプラクティス
EOF
```

**完了目安**: ドキュメント更新

---

## 🔧 高度な設定

### カスタムコマンドの追加
```bash
# プロジェクト固有のコマンド
cat > .claude/commands/project:deploy << 'EOF'
name: "デプロイ実行"  
description: "本番環境へのデプロイを実行します"

steps:
  1:
    title: "デプロイ前チェック"
    actions:
      - "全テストの実行・確認"
      - "セキュリティスキャン実行"
      - "デプロイ対象の確認"
  
  2:
    title: "デプロイ実行"
    actions:
      - "本番環境へのデプロイ"
      - "ヘルスチェック実行"
      - "ロールバック準備"
EOF
```

### テンプレートの条件分岐
```yaml
# 条件付きステップの例
steps:
  3:
    title: "言語別テスト"
    conditions:
      - if: "language == 'python'"
        actions: ["python -m pytest"]
      - if: "language == 'nodejs'"  
        actions: ["npm test"]
      - else:
        actions: ["echo 'Unknown language'", "exit 1"]
```

### Hook 統合の確認
```bash
# テンプレート実行時の Hook 動作確認
cat > .claude/hooks/pre-tool/template-guard.sh << 'EOF'
#!/bin/bash
# テンプレート実行前の確認
if [[ "$CLAUDE_COMMAND" =~ project:(new-feature|fix-bug) ]]; then
  echo "TDD テンプレート実行開始: $CLAUDE_COMMAND"
  # 必要な前提条件チェック
  git status --porcelain | grep -q "^M " && echo "WARNING: 未コミットの変更があります"
fi
EOF
chmod +x .claude/hooks/pre-tool/template-guard.sh
```

---

## ✅ 完了チェックリスト

### コマンドテンプレート作成
- [ ] `/project:new-feature` テンプレート作成
- [ ] 10 ステップ TDD フローの定義
- [ ] Hook 統合・制約の設定
- [ ] `/project:fix-bug` テンプレート作成
- [ ] バグ修正フローの定義

### ドキュメント整備
- [ ] `docs/30_ai_workflow/commands.md` 作成
- [ ] コマンド早見表の整備
- [ ] 使用パターン・制約の記載
- [ ] 関連ドキュメントのリンク

### 動作テスト
```bash
# コマンド登録確認
ls .claude/commands/
cat .claude/commands/project:new-feature | head -10

# ドキュメント確認
cat docs/30_ai_workflow/commands.md | grep "##"

# Hook 統合テスト
.claude/hooks/pre-tool/template-guard.sh
```

### カスタマイズ (オプション)
- [ ] プロジェクト固有コマンドの追加
- [ ] 条件分岐ロジックの実装
- [ ] Hook との統合確認

**次のステップ**: [パイロットテスト](pilot_testing.md)