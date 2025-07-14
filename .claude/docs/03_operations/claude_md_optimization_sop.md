# CLAUDE.md最適化SOP（Standard Operating Procedure）

> **目的**: ADR-007決定に基づくCLAUDE.md最小核化・ドキュメント品質最適化の具体的実装手順

## 📋 運用手順概要

### 対象者
- プロジェクト管理者
- ドキュメント保守担当者
- Claude Code ワークスペース管理者

### 前提条件
- [ADR-007: ドキュメント品質最適化システム](../../../governance/adr/007-document-quality-optimization-system.md) 承認済み
- `.claude/docs/` ディレクトリ構造の理解
- Git バージョン管理の基本操作知識

---

## 🎯 1. CLAUDE.md最小核化手順

### 1.1 事前準備・バックアップ

#### 現状分析
```bash
# 1. 現在のCLAUDE.md基本情報取得
- [ ] wc -l CLAUDE.md  # 行数確認
- [ ] grep -c "^##" CLAUDE.md  # セクション数確認
- [ ] grep -o "\[.*\](" CLAUDE.md | wc -l  # 内部リンク数確認

# 2. バックアップ作成
- [ ] cp CLAUDE.md CLAUDE.md.backup.$(date +%Y%m%d)
- [ ] git add . && git commit -m "backup: CLAUDE.md before optimization"
```

#### 分析レポート作成
```bash
# 3. セクション別行数分析
- [ ] awk '/^## / {if(section!="") print section, NR-start_line; section=$0; start_line=NR} END {if(section!="") print section, NR-start_line+1}' CLAUDE.md > claude_md_analysis.txt
- [ ] cat claude_md_analysis.txt  # セクション別行数確認
```

### 1.2 コンテンツ分類・分離計画

#### 核心情報の特定
核心情報基準：
- **頻度**: Claude が日常的に参照する（週3回以上）
- **緊急性**: 開発中断・ブロック時に即座に必要
- **簡潔性**: 5行以内で表現可能

#### 分離対象コンテンツの特定
```bash
# 分離対象セクション特定
- [ ] ## AI完璧主義症候群対策 の詳細説明部分
- [ ] TDD・YAGNI・KISS の詳細実践方法
- [ ] Hook システムの詳細設定・トラブルシューティング
- [ ] 具体的なコマンド例・実行結果例
- [ ] 長文の背景説明・理論解説
```

#### 分離先ファイル構造
```
.claude/docs/
├── anti_perfectionism.md      # AI完璧主義対策詳細
├── tdd_detailed_guide.md      # TDD実践詳細ガイド
├── hook_troubleshooting.md    # Hook詳細トラブルシューティング
├── development_examples.md    # 開発実践例・ケーススタディ
└── command_reference.md       # コマンドリファレンス・実行例
```

### 1.3 詳細ガイダンス分離実装

#### anti_perfectionism.md 作成
```bash
- [ ] ファイル作成: .claude/docs/anti_perfectionism.md
- [ ] Front-Matter追加:
  ```yaml
  ---
  title: "AI完璧主義症候群防止詳細ガイド"
  status: "active"
  category: "reference"
  created: "2025-07-14"
  tags: ["ai-perfectionism", "quality-control", "best-practices"]
  priority: "high"
  ---
  ```
- [ ] 既存CLAUDE.mdから詳細説明部分を移行:
  - [ ] AI完璧主義症候群の背景・心理学的説明
  - [ ] 具体的症状例・実例
  - [ ] 対策の詳細理論・エビデンス
  - [ ] ケーススタディ・失敗例
```

#### tdd_detailed_guide.md 作成
```bash
- [ ] ファイル作成: .claude/docs/tdd_detailed_guide.md
- [ ] 内容移行:
  - [ ] TDD Red-Green-Refactor の詳細解説
  - [ ] プロジェクト別TDD実践方法
  - [ ] テストフレームワーク別ガイド
  - [ ] TDD違反時の具体的対処法
  - [ ] 実践例・コマンド実行例
```

#### hook_troubleshooting.md 作成
```bash
- [ ] ファイル作成: .claude/docs/hook_troubleshooting.md
- [ ] 内容移行:
  - [ ] Hook設定詳細・JSON構文
  - [ ] 権限問題・CRLF問題解決法
  - [ ] デバッグ手順・ログ確認方法
  - [ ] 緊急時バイパス・復旧手順
  - [ ] プラットフォーム固有問題対応
```

### 1.4 最小核CLAUDE.md 再構築

#### 核心セクション再設計
```markdown
# CLAUDE.md (最小核版 - 目標≤150行)

## 🎯 開発原則（核心）
- **TDD**: テスト駆動開発を徹底
- **YAGNI**: 必要な機能のみ実装  
- **KISS**: シンプルな設計を維持

## ⚠️ AI完璧主義対策（重要）
### 禁止
- 95%→100%を狙うリファクタ
- 5ファイル以上の同時新規作成
- 2026年以降のロードマップ

### 自己チェック
1. 今すぐ必要か？
2. 実証された価値は？
3. 最もシンプルか？

> 詳細・具体例: [AI完璧主義防止詳細ガイド](.claude/docs/anti_perfectionism.md)

## 🔧 基本コマンド
```bash
# 新機能開発
/project:new-feature [issue_number]

# バグ修正
/project:fix-bug [issue_number]

# テスト実行
pytest
pytest --cov=src --cov-report=term-missing
```

## 🛡️ 品質ガード（Hook）
- **PreToolUse**: TDD準拠・憲法チェック
- **PostToolUse**: 未使用コード検出
- **Stop**: カバレッジ確認

> 詳細設定・トラブル: [Hook詳細ガイド](.claude/docs/hook_troubleshooting.md)

## 📚 詳細リファレンス
- [TDD実践詳細](.claude/docs/tdd_detailed_guide.md)
- [開発実践例](.claude/docs/development_examples.md)
- [コマンドリファレンス](.claude/docs/command_reference.md)
```

#### 実装手順
```bash
- [ ] 新CLAUDE.md 下書き作成: CLAUDE.md.new
- [ ] 核心情報のみ残存・詳細は参照リンク化
- [ ] 行数確認: wc -l CLAUDE.md.new  # ≤150行目標
- [ ] 内部リンク確認: 全リンクの動作テスト
- [ ] 置き換え実行: mv CLAUDE.md.new CLAUDE.md
```

---

## 📝 2. 教育的メッセージテンプレート統一

### 2.1 メッセージテンプレートライブラリ作成

#### lib/message_templates.sh 実装
```bash
- [ ] ファイル作成: .claude/hooks/lib/message_templates.sh
- [ ] 基本テンプレート関数実装:
```

```bash
#!/bin/bash
# message_templates.sh - 教育的ブロックメッセージ統一ライブラリ

# 統一教育的ブロック関数
output_educational_block() {
    local violation_type="$1"
    local cause="$2"
    local solution="$3" 
    local example="$4"
    local detail_link="${5:-}"
    
    cat >&2 <<EOF
🚫 **${violation_type}**

**原因**: ${cause}

**対処**: ${solution}

**再試行**: ${example}

$(if [[ -n "$detail_link" ]]; then echo "詳細: $detail_link"; fi)
EOF
}

# 違反タイプ別メッセージ生成
generate_tdd_violation_message() {
    local file_path="$1"
    local test_file_suggestion="${2:-tests/test_$(basename "$file_path" .py).py}"
    
    output_educational_block \
        "TDD_VIOLATION" \
        "テストコードの変更なしに実装ファイルを変更しようとしています" \
        "対応するテストファイルを先に作成・更新してください" \
        "例: touch $test_file_suggestion && pytest $test_file_suggestion" \
        ".claude/docs/tdd_detailed_guide.md"
}

generate_perfectionism_violation_message() {
    local file_count="$1"
    local max_allowed="$2"
    
    output_educational_block \
        "AI_PERFECTIONISM_VIOLATION" \
        "${file_count}ファイルの同時作成はAI完璧主義症候群の兆候です" \
        "作業を小分けし、必要最小限（${max_allowed}ファイル以下）のみ作成してください" \
        "YAGNI原則で見直し: 今すぐ必要な1-2ファイルから開始" \
        ".claude/docs/anti_perfectionism.md"
}

generate_coverage_violation_message() {
    local current_coverage="$1"
    local required_coverage="$2"
    local project="$3"
    
    output_educational_block \
        "COVERAGE_VIOLATION" \
        "テストカバレッジ ${current_coverage}% < ${required_coverage}% (${project}基準)" \
        "不足しているテストケースを追加してください" \
        "実行: pytest --cov=src --cov-report=term-missing" \
        ".claude/docs/tdd_detailed_guide.md#coverage"
}
```

### 2.2 既存Hook統合・メッセージ置き換え

#### quality-gate.sh 統合
```bash
- [ ] .claude/hooks/quality-gate.sh にテンプレートライブラリ統合
- [ ] 既存メッセージ出力を統一関数呼び出しに置き換え:

# Before (例)
echo "Error: TDD violation detected" >&2

# After
source "$(dirname "$0")/lib/message_templates.sh"
generate_tdd_violation_message "$file_path"
```

#### 統一性確認
```bash
- [ ] 全Hook段階での統一フォーマット確認
- [ ] Markdown構造の一貫性検証
- [ ] Claude 解釈テスト: 実際のメッセージ出力での再試行確認
```

---

## 📊 3. 効果測定・品質確認

### 3.1 最適化効果の定量測定

#### CLAUDE.md メトリクス
```bash
- [ ] 行数測定: wc -l CLAUDE.md  # 目標≤150行
- [ ] セクション数: grep -c "^##" CLAUDE.md  # 目標≤8セクション
- [ ] 内部リンク数: grep -o "\[.*\](" CLAUDE.md | wc -l  # 目標5-8個
- [ ] 文字数: wc -c CLAUDE.md  # 削減率計算
```

#### Before/After 比較
```bash
- [ ] 最適化前後比較レポート作成:
  - 行数削減率: (旧行数-新行数)/旧行数 × 100
  - 詳細分離ファイル数: ls .claude/docs/*.md | wc -l
  - 総文字数変化: 分離前後の全体文字数
```

### 3.2 Claude 体験品質の検証

#### 記憶効率テスト
```bash
- [ ] 長時間セッション（2時間+）での憲法記憶維持確認
- [ ] Claude による CLAUDE.md 内容要約精度テスト
- [ ] 基本原則（TDD・YAGNI・KISS）の自発的言及率測定
```

#### 教育的メッセージ効果測定
```bash
- [ ] Claude 再試行成功率測定:
  - メッセージ出力後の次回アクション成功率
  - 同一違反の再発率（7日間）
  - エラー解決に要する試行回数

- [ ] メッセージ品質評価:
  - Claude による問題理解正確率
  - 提案された解決策の実行成功率
  - 詳細リンク参照率
```

### 3.3 開発者体験の評価

#### 情報発見効率
```bash
- [ ] 新規開発者オンボーディング時間測定
- [ ] 特定情報（TDD手順・Hook設定等）への到達時間
- [ ] ドキュメント更新・保守にかかる作業時間
```

#### アンケート・フィードバック収集
```bash
- [ ] 開発者体験アンケート実施:
  - CLAUDE.md 可読性（5段階評価）
  - 詳細情報への発見しやすさ
  - エラーメッセージの分かりやすさ
  - 全体的な開発効率改善実感
```

---

## 🔄 4. 継続運用・改善プロセス

### 4.1 定期メンテナンス手順

#### 週次確認
```bash
- [ ] CLAUDE.md 行数監視: wc -l CLAUDE.md >> logs/claude_md_metrics.log
- [ ] 新規追加内容の分離要否判定
- [ ] 教育的メッセージ効果確認: violations.jsonl 解析
- [ ] 詳細ドキュメントの更新状況確認
```

#### 月次最適化
```bash
- [ ] CLAUDE.md 核心情報の見直し:
  - 参照頻度の低いセクション特定
  - 詳細分離候補の抽出
  - 内部リンクの整合性確認

- [ ] 教育的メッセージ改善:
  - 再試行成功率の低いメッセージ特定
  - 新しい違反パターンへの対応
  - メッセージテンプレートの調整
```

#### 四半期レビュー
```bash
- [ ] 全体アーキテクチャ有効性評価:
  - 最小核化戦略の妥当性確認
  - 詳細分離ファイル構造の最適性
  - Claude 体験改善効果の定量評価

- [ ] 次期改善計画策定:
  - 新たな最適化機会の特定
  - ツール・自動化導入検討
  - 開発者体験向上施策
```

### 4.2 緊急時・問題対応

#### CLAUDE.md 肥大化対応
```bash
# 緊急時の肥大化検出・対応
- [ ] 肥大化検出: if [ $(wc -l < CLAUDE.md) -gt 150 ]; then echo "ALERT: CLAUDE.md exceeds 150 lines"; fi
- [ ] 緊急分離作業: 最新追加セクションの詳細ファイル分離
- [ ] 復旧確認: 核心情報の欠落なし・リンク整合性確認
```

#### 教育的メッセージ問題対応
```bash
# Claude 再試行失敗率上昇時
- [ ] 問題メッセージ特定: violations.jsonl から再発率の高い violation_type 特定
- [ ] メッセージ改善: 具体例・再試行手順の明確化
- [ ] 効果確認: 改善後1週間での成功率測定
```

#### リンク切れ・整合性問題
```bash
# 内部リンク整合性確認
- [ ] リンクチェック: find .claude/docs -name "*.md" -exec grep -l "^# " {} \; | while read file; do echo "Check: $file"; done
- [ ] 自動修正: 移動・削除ファイルのリンク更新
- [ ] CI統合: GitHub Actions でのリンクチェック自動化
```

### 4.3 自動化・ツール統合

#### CLAUDE.md 監視自動化
```bash
# .github/workflows/claude-md-monitor.yml 設定
- [ ] 行数監視Action設定
- [ ] 肥大化時のIssue自動作成
- [ ] 定期レポート生成・通知
```

#### メトリクス収集自動化
```bash
# weekly_claude_optimization_report.sh 作成
- [ ] CLAUDE.md メトリクス自動収集
- [ ] 教育的メッセージ効果分析
- [ ] 改善提案の自動生成
- [ ] Slack・メール通知統合
```

---

## 📚 5. 関連資料・リファレンス

### 5.1 実装基準ドキュメント
- [ADR-007: ドキュメント品質最適化システム](../../../governance/adr/007-document-quality-optimization-system.md)
- [AI完璧主義防止計画](../../tmp/ai_perfectionism_prevention_plan.md)
- [統合品質ガードシステム技術仕様](../04_reference/integrated_quality_gate_system.md)

### 5.2 分離後詳細ガイド
- [AI完璧主義防止詳細ガイド](.claude/docs/anti_perfectionism.md)
- [TDD実践詳細ガイド](.claude/docs/tdd_detailed_guide.md)
- [Hook詳細トラブルシューティング](.claude/docs/hook_troubleshooting.md)
- [開発実践例・ケーススタディ](.claude/docs/development_examples.md)

### 5.3 品質管理関連
- [ドキュメント複雑性制御システム](../04_reference/document-complexity-control-system.md)
- [Hook統合実装チェックリスト](hook_integration_checklist.md)
- [AI完璧主義監視](ai_perfectionism_monitoring.md)

---

## ✅ 完了チェックリスト

### 実装完了確認
- [ ] **CLAUDE.md最小核化**: ≤150行達成・核心情報のみ残存
- [ ] **詳細分離**: 4-5個の詳細ガイドファイル作成完了
- [ ] **リンク整合性**: 全内部リンクの動作確認完了
- [ ] **教育的メッセージ統一**: 統一テンプレート適用・Hook統合完了

### 品質基準達成確認
- [ ] **行数削減**: 25%削減目標達成（200行→150行）
- [ ] **Claude再試行成功率**: 95%目標達成確認
- [ ] **情報発見時間**: 50%短縮目標達成確認
- [ ] **保守効率**: 90%改善目標達成確認

### 運用準備完了確認
- [ ] **定期メンテナンス手順**: 週次・月次・四半期レビュー手順確立
- [ ] **監視・アラート**: 自動監視・問題検出システム動作確認
- [ ] **継続改善**: フィードバック収集・改善サイクル確立
- [ ] **ドキュメント**: 運用手順・トラブルシューティング完備

---

*CLAUDE.md最適化SOP v1.0*  
*基準文書: [ADR-007](../../../governance/adr/007-document-quality-optimization-system.md)*  
*作成日: 2025-07-14*  
*想定作業期間: 3-4日*