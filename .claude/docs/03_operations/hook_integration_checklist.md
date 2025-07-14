# Hook統合実装チェックリスト

> **目的**: ADR-006統合品質ガードシステムの段階的実装ガイド

## 📋 実装概要

### 対象システム
- **統合対象**: 既存6スクリプト → quality-gate.sh 1スクリプト
- **設定外部化**: quality-gate.yaml による動的設定
- **ログ統合**: violations.jsonl + SQLite DB
- **可視化**: HTML ダッシュボード生成

### 実装期間
- **予定**: 5-6日（Phase 1: 1-2日、Phase 2: 2-3日、Phase 3: 1-2日）
- **検証**: 各Phase完了時点での動作確認必須

---

## 🎯 Phase 1: 基盤構築（1-2日）

### 1.1 環境準備・依存関係

#### 前提条件確認
- [ ] **Git状態確認**: 未コミットの変更をバックアップ
- [ ] **Claude Code停止**: 実装中のHook競合を避ける
- [ ] **権限確認**: .claude/hooks/ ディレクトリへの書き込み権限

#### システム依存関係インストール
```bash
# Ubuntu/Debian
- [ ] sudo apt-get update
- [ ] sudo apt-get install -y yq sqlite3 jq

# macOS
- [ ] brew install yq sqlite3 jq

# 共通確認
- [ ] yq --version  # 4.0+ 必須
- [ ] sqlite3 --version  # 3.0+ 必須
- [ ] jq --version  # 1.6+ 推奨
```

#### Node.js 依存関係（ダッシュボード用）
```bash
- [ ] node --version  # 18+ 推奨
- [ ] npm install -g @observablehq/plot sqlite3
- [ ] node -e "console.log(require('@observablehq/plot'))"  # 動作確認
```

### 1.2 ディレクトリ構造準備

#### 新規ディレクトリ作成
```bash
- [ ] mkdir -p .claude/hooks/lib
- [ ] mkdir -p .claude/hooks/scripts  
- [ ] mkdir -p logs
- [ ] chmod 755 .claude/hooks/lib .claude/hooks/scripts logs
```

#### 既存スクリプトバックアップ
```bash
- [ ] cp -r .claude/hooks .claude/hooks.backup.$(date +%Y%m%d)
- [ ] ls -la .claude/hooks.backup.*  # バックアップ確認
```

### 1.3 共通ライブラリ実装

#### lib/helpers.sh 基本構造
```bash
- [ ] ファイル作成: .claude/hooks/lib/helpers.sh
- [ ] 基本関数テンプレート実装:
  - [ ] load_config_from_yaml()
  - [ ] detect_project_from_path()
  - [ ] log_violation()
  - [ ] output_educational_block()
  - [ ] is_implementation_file()
  - [ ] has_recent_test_changes()
```

#### 設定読み込み機能テスト
```bash
- [ ] 仮quality-gate.yaml作成（最小構成）
- [ ] source .claude/hooks/lib/helpers.sh
- [ ] load_config_from_yaml  # エラーなく動作確認
- [ ] echo "$MAX_LINES"  # 設定値読み込み確認
```

### 1.4 設定ファイル設計

#### quality-gate.yaml 初版作成
```bash
- [ ] ファイル作成: .claude/hooks/quality-gate.yaml
- [ ] defaults セクション実装:
  - [ ] max_lines: 500
  - [ ] coverage_threshold: 60
  - [ ] max_files_creation: 5
- [ ] projects セクション実装:
  - [ ] danbouru_advanced_wildcard 設定
  - [ ] pdi 設定  
  - [ ] workspace 設定
```

#### YAML構文・スキーマ検証
```bash
- [ ] yq eval '.defaults' .claude/hooks/quality-gate.yaml
- [ ] yq eval '.projects.danbouru_advanced_wildcard' .claude/hooks/quality-gate.yaml
- [ ] 構文エラーなし確認
```

---

## ⚙️ Phase 2: Hook機能統合（2-3日）

### 2.1 quality-gate.sh 統合スクリプト実装

#### 基本構造・フェーズ分岐
```bash
- [ ] ファイル作成: .claude/hooks/quality-gate.sh
- [ ] shebang・set オプション設定: #!/bin/bash, set -euo pipefail
- [ ] 共通ライブラリ読み込み: source lib/helpers.sh
- [ ] Hook入力解析ロジック実装
- [ ] フェーズ分岐ロジック実装 (pre|post|stop)
- [ ] 実行権限設定: chmod +x .claude/hooks/quality-gate.sh
```

#### Pre Hook 機能統合
```bash
- [ ] check_tdd_compliance() 関数実装
  - [ ] 実装ファイル判定ロジック
  - [ ] 最近のテスト変更確認ロジック  
  - [ ] 教育的ブロックメッセージ出力
- [ ] check_constitution_compliance() 関数実装
  - [ ] MultiEdit大量作成検出
  - [ ] 長期計画文書検出  
  - [ ] ファイル行数制限チェック
```

#### Post Hook 機能統合
```bash
- [ ] check_unused_code() 関数実装
  - [ ] Python: vulture 統合
  - [ ] JavaScript: ESLint統合
  - [ ] 言語別分岐処理
- [ ] log_violations() 関数実装
  - [ ] violations.jsonl 形式出力
  - [ ] タイムスタンプ・コンテキスト情報付与
```

#### Stop Hook 機能統合  
```bash
- [ ] check_coverage_threshold() 関数実装
  - [ ] プロジェクト別カバレッジ基準適用
  - [ ] pytest/jest 等フレームワーク対応
  - [ ] カバレッジ不足時の教育的ブロック
- [ ] generate_reports() 関数実装
  - [ ] セッション終了時レポート生成
  - [ ] 統計情報SQLite保存
```

### 2.2 統合テスト・既存機能検証

#### 単体機能テスト
```bash
# TDD Guard テスト
- [ ] echo '{"tool_name":"Edit","tool_input":{"file_path":"src/main.py"}}' | .claude/hooks/quality-gate.sh pre
- [ ] exit code 2 確認（TDD違反検出）

# Constitution Guard テスト  
- [ ] 6ファイル同時作成のMultiEdit JSON作成
- [ ] .claude/hooks/quality-gate.sh pre < test_input.json
- [ ] exit code 2 確認（大量作成違反検出）

# Unused Code Detection テスト
- [ ] Python未使用関数を含むファイル作成
- [ ] .claude/hooks/quality-gate.sh post < test_input.json  
- [ ] 未使用コード検出メッセージ確認

# Coverage Check テスト
- [ ] カバレッジ不足の模擬状況作成
- [ ] .claude/hooks/quality-gate.sh stop
- [ ] カバレッジ不足検出・ブロック確認
```

#### 既存機能との互換性確認
```bash
- [ ] 既存 tdd-guard.sh と同等の動作確認
- [ ] 既存 unused-detector.sh と同等の動作確認
- [ ] 既存 coverage-check.sh と同等の動作確認
- [ ] 教育的メッセージの質・内容が同等以上
```

### 2.3 違反ログ・SQLite統合

#### violations.jsonl ログ機能
```bash
- [ ] ログディレクトリ作成: mkdir -p logs
- [ ] JSON Lines形式出力確認
- [ ] 構造化データ形式検証:
  - [ ] timestamp フィールド（ISO8601形式）
  - [ ] violation_type フィールド  
  - [ ] file_path フィールド
  - [ ] context フィールド
  - [ ] project フィールド
```

#### SQLite DB 設計・初期化
```bash
- [ ] データベース設計ファイル作成: logs/init_db.sql
- [ ] violations テーブル作成
- [ ] coverage_history テーブル作成  
- [ ] metrics_summary テーブル作成
- [ ] インデックス作成
- [ ] 初期化実行: sqlite3 logs/quality.db < logs/init_db.sql
```

#### JSON→SQLite データ取り込み
```bash
- [ ] violations.jsonl → SQLite 取り込みスクリプト作成
- [ ] バッチ処理・重複回避ロジック実装
- [ ] データ取り込みテスト実行
- [ ] SQLiteクエリでデータ確認: sqlite3 logs/quality.db "SELECT * FROM violations LIMIT 5"
```

---

## 📊 Phase 3: 可視化・本格運用（1-2日）

### 3.1 KPI ダッシュボード実装

#### dashboard_generator.js 作成
```bash
- [ ] ファイル作成: .claude/hooks/scripts/dashboard_generator.js
- [ ] Observable Plot ライブラリ統合
- [ ] SQLite データ読み込み機能実装:
  - [ ] getViolationsData()
  - [ ] getCoverageData()  
  - [ ] getSummaryStats()
- [ ] HTML生成機能実装
- [ ] 実行権限設定: chmod +x .claude/hooks/scripts/dashboard_generator.js
```

#### ダッシュボード生成テスト
```bash
- [ ] node .claude/hooks/scripts/dashboard_generator.js
- [ ] quality_dashboard.html 生成確認
- [ ] ブラウザでHTMLファイル表示確認
- [ ] チャート・グラフ正常表示確認
- [ ] 違反データ・カバレッジデータ反映確認
```

### 3.2 週次分析バッチ実装

#### analyze_violations.sh 作成  
```bash
- [ ] ファイル作成: .claude/hooks/scripts/analyze_violations.sh
- [ ] SQLite集計クエリ実装
- [ ] Markdown レポート生成機能
- [ ] 頻出違反パターン分析
- [ ] 改善提案自動生成ロジック
- [ ] 実行権限設定: chmod +x .claude/hooks/scripts/analyze_violations.sh
```

#### 週次レポート生成テスト
```bash
- [ ] .claude/hooks/scripts/analyze_violations.sh
- [ ] logs/weekly_analysis.md 生成確認
- [ ] レポート内容妥当性確認:
  - [ ] 違反頻度ランキング
  - [ ] 改善提案内容
  - [ ] プロジェクト別統計
```

### 3.3 Claude Code統合・本格運用

#### .claude/settings.json 更新
```bash
- [ ] 既存settings.json バックアップ
- [ ] hooks セクション更新:
  - [ ] PreToolUse: quality-gate.sh pre
  - [ ] PostToolUse: quality-gate.sh post  
  - [ ] Stop: quality-gate.sh stop
- [ ] 構文検証: jq . .claude/settings.json
```

#### 統合動作テスト  
```bash
- [ ] Claude Code 再起動
- [ ] 実際の Edit/MultiEdit 操作実行
- [ ] Hook実行ログ確認
- [ ] 教育的ブロック動作確認
- [ ] 違反ログ記録確認: tail -f logs/violations.jsonl
```

#### 既存スクリプト移行・削除
```bash
- [ ] 統合動作確認完了後の旧スクリプト削除:
  - [ ] rm .claude/hooks/pre-tool/tdd-guard.sh
  - [ ] rm .claude/hooks/post-tool/unused-detector.sh
  - [ ] rm .claude/hooks/stop/coverage-check.sh
- [ ] 統合後も正常動作確認
- [ ] 削除ファイルのバックアップ確認: ls -la .claude/hooks.backup.*
```

---

## ✅ 完了確認・品質チェック

### 最終統合確認チェックリスト

#### 機能完全性確認
- [ ] **TDD Guard**: テスト変更なし実装変更を100%ブロック
- [ ] **Constitution Guard**: 大量ドキュメント作成・長期計画を100%ブロック  
- [ ] **Unused Code Detection**: Python/JavaScript未使用コード検出
- [ ] **Coverage Check**: プロジェクト別閾値でカバレッジ不足をブロック
- [ ] **教育的ブロック**: 分かりやすいエラーメッセージ・再試行指示

#### 設定・ログ確認
- [ ] **YAML設定**: プロジェクト別閾値が正しく適用される
- [ ] **violations.jsonl**: 構造化ログが正常出力される
- [ ] **SQLite DB**: 違反・カバレッジデータが蓄積される
- [ ] **ダッシュボード**: リアルタイムメトリクス可視化動作
- [ ] **週次レポート**: 自動分析・改善提案生成動作

#### パフォーマンス・運用性確認
- [ ] **Hook実行時間**: 各段階2秒以内で完了
- [ ] **依存関係**: yq, sqlite3, jq, node が正常動作
- [ ] **エラーハンドリング**: 依存ツール不在時の適切なフォールバック
- [ ] **緊急バイパス**: CLAUDE_HOOKS_DISABLED=true での無効化動作

### 成功指標達成確認

#### 定量指標
- [ ] **Hook保守効率**: 6ファイル→1ファイル（83%削減達成）
- [ ] **設定変更効率**: 閾値変更がYAML編集のみで完了
- [ ] **違反検出精度**: 98%+の品質チェック違反検出
- [ ] **ダッシュボード生成**: 5分以内での自動更新完了

#### 定性指標  
- [ ] **開発者体験**: Hook設定・カスタマイズの簡素化実感
- [ ] **運用自動化**: 手動違反分析→自動週次レポート移行
- [ ] **拡張性**: 新プロジェクト・メトリクス追加の容易性確認
- [ ] **可視性**: リアルタイム品質状況把握の改善実感

---

## 🚨 トラブルシューティング

### よくある問題と対処法

#### Hook実行エラー
```bash
# yq not found
- [ ] 対処: sudo apt-get install -y yq  # または brew install yq
- [ ] 確認: which yq && yq --version

# SQLite access error  
- [ ] 対処: chmod 666 logs/quality.db
- [ ] 確認: sqlite3 logs/quality.db "SELECT 1"

# Node.js module error
- [ ] 対処: npm install -g @observablehq/plot sqlite3
- [ ] 確認: node -e "console.log(require('@observablehq/plot'))"
```

#### 設定・データ不整合
```bash
# YAML構文エラー
- [ ] 確認: yq eval '.defaults' .claude/hooks/quality-gate.yaml
- [ ] 修正: エラー行の構文修正

# violations.jsonl 破損
- [ ] バックアップ: cp logs/violations.jsonl logs/violations.jsonl.backup
- [ ] 修復: 不正行削除・JSON構文修正

# SQLite DB 破損
- [ ] 復旧: cp logs/quality.db.backup logs/quality.db
- [ ] 再作成: rm logs/quality.db && sqlite3 logs/quality.db < logs/init_db.sql
```

### 緊急時対応

#### Hook全体無効化
```bash
# 一時的無効化
- [ ] export CLAUDE_HOOKS_DISABLED=true
- [ ] Claude Code 再起動

# 設定復旧
- [ ] cp .claude/hooks.backup.YYYYMMDD/* .claude/hooks/
- [ ] Claude Code 再起動
```

#### データ復旧
```bash
# 全データバックアップ
- [ ] cp -r logs logs.backup.$(date +%Y%m%d_%H%M)
- [ ] cp .claude/hooks/quality-gate.yaml .claude/hooks/quality-gate.yaml.backup

# 初期状態復旧
- [ ] git checkout .claude/settings.json
- [ ] rm -rf .claude/hooks/quality-gate.*
- [ ] cp -r .claude/hooks.backup.latest/* .claude/hooks/
```

---

## 📚 実装後の継続運用

### 定期メンテナンス

#### 毎週
- [ ] logs/weekly_analysis.md レビュー・改善事項確認
- [ ] quality_dashboard.html 確認・異常値チェック
- [ ] violations.jsonl ファイルサイズ確認・ローテーション検討

#### 毎月  
- [ ] SQLite DB メンテナンス: VACUUM, ANALYZE実行
- [ ] 設定見直し: プロジェクト別閾値の適切性評価
- [ ] 依存関係更新: yq, sqlite3, Node.jsライブラリ

#### 四半期
- [ ] 統合システム効果測定・KPI評価
- [ ] 新しい品質チェック項目の検討・追加
- [ ] アーキテクチャ見直し・次期改善計画策定

### 拡張・カスタマイズ

#### 新プロジェクト追加手順
1. [ ] quality-gate.yaml の projects セクションに追加
2. [ ] プロジェクト固有の test_command 設定
3. [ ] 動作テスト・閾値調整

#### 新品質チェック追加手順  
1. [ ] lib/helpers.sh に check_custom_rule() 関数追加
2. [ ] quality-gate.sh の適切なフェーズに統合
3. [ ] 教育的ブロックメッセージ設計・実装
4. [ ] テスト・検証実施

---

*Hook統合実装チェックリスト v1.0*  
*基準文書: [ADR-006](../../../governance/adr/006-integrated-quality-guard-system.md), [技術仕様書](../04_reference/integrated_quality_gate_system.md)*  
*作成日: 2025-07-14*  
*想定実装期間: 5-6日*