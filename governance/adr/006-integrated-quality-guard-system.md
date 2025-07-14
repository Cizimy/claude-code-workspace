# ADR-006: 統合品質ガードシステムの技術統合決定

## Status
Proposed

## Date
2025-07-14

## Context

### 現状の技術的課題
Claude Code Workspace において、AI完璧主義防止システム（ADR-003）導入後、以下の技術的複雑性が顕在化している：

#### Hook システムの分散化問題
1. **スクリプト乱立**: PreToolUse, PostToolUse, Stop の各段階で個別スクリプト（6ファイル）
2. **設定ハードコード**: プロジェクト別閾値がスクリプト内に埋め込まれ保守困難
3. **重複処理**: 各Hookで類似の初期化・ログ出力処理が散在
4. **学習機能欠如**: 違反検出後の手動対応、改善サイクルの自動化なし

#### 具体的改善要求（ai_perfectionism_prevention_plan.md 戦略A,B,E,F）
- **A. ガード統廃合**: 6スクリプト→1統合スクリプト化
- **B. 動的パラメータ化**: YAML外部設定による閾値管理  
- **E. 学習ループ自動化**: violations.jsonl蓄積とバッチ分析
- **F. 軽量KPIダッシュボード**: SQLite+HTML最小構成可視化

### 技術的実現可能性の確認済み事項
- **Hook統合**: 同一スクリプトでのPreToolUse/PostToolUse/Stop対応確認済み
- **YAML設定**: 外部ファイル読み込みによる動的設定変更可能
- **違反ログ**: Stop Hook でのJSONL形式ログ出力確認済み
- **軽量ダッシュボード**: SQLite+Observable Plot での HTML生成実証済み

## Decision

統合品質ガードシステムを技術基盤として採用し、以下4つの統合技術決定を実装する：

### 戦略A: Hook統廃合アーキテクチャ
**実装**: `quality-gate.sh` 単一統合スクリプト
```bash
# 統合実行モデル
quality-gate.sh $HOOK_PHASE $HOOK_INPUT
├── pre)  check_tdd + check_constitution
├── post) check_unused + check_violations  
└── stop) check_coverage + generate_reports
```

**技術仕様**:
- 共通ライブラリ `lib/helpers.sh` によるコード重複排除
- 環境変数 `hook_event_name` による実行段階分岐
- 統一ログフォーマットによる処理追跡

### 戦略B: 外部設定駆動アーキテクチャ
**実装**: `quality-gate.yaml` 設定ファイル
```yaml
defaults:
  max_lines: 500
  coverage_threshold: 60
  max_files_creation: 5
projects:
  danbouru_advanced_wildcard:
    coverage_threshold: 80
    max_lines: 300
```

**技術仕様**:
- `yq` コマンドによるYAML→環境変数変換
- プロジェクト階層継承（defaults < project-specific）
- 設定変更時のコード変更不要化

### 戦略E: 自動学習ループアーキテクチャ  
**実装**: `violations.jsonl` + 週次分析バッチ
```bash
# 違反検出時の自動ログ記録
echo '{"timestamp":"'$(date -Iseconds)'","violation_type":"'$TYPE'","file":"'$FILE'","context":"'$CONTEXT'"}' >> logs/violations.jsonl

# 週次バッチでの頻出パターン分析
sqlite3 quality.db "SELECT violation_type, COUNT(*) FROM violations WHERE date > date('now', '-7 days') GROUP BY violation_type ORDER BY COUNT(*) DESC"
```

**技術仕様**:
- JSON Lines形式による構造化ログ
- SQLite統合による集計・分析機能
- 頻出違反パターンの自動ランキング・アラート

### 戦略F: 軽量KPI可視化アーキテクチャ
**実装**: SQLite + Observable Plot による HTML ダッシュボード
```javascript
// dashboard_generator.js (pseudo)
const violations = db.prepare("SELECT * FROM violations WHERE date > ?").all(last_week);
const coverage = db.prepare("SELECT * FROM coverage_history WHERE date > ?").all(last_week);
// → HTML生成 → quality_dashboard.html
```

**技術仕様**:
- SQLite 単一DBファイルによるメトリクス統合管理
- Observable Plot ライブラリによる軽量可視化
- フルスタック監視システム導入の先送り（Grafana等）

## Consequences

### 期待される正の影響

#### 1. 技術的負債の大幅削減
- **保守対象**: 6スクリプト → 1スクリプト（83%削減）
- **設定変更**: コード変更不要（YAML編集のみ）
- **重複コード**: lib/共通化による30%コード量削減

#### 2. 運用自動化の実現
- **違反分析**: 手動→自動バッチによる週次レポート
- **改善提案**: SQLiteクエリによる定量的改善項目特定
- **ダッシュボード**: リアルタイム品質メトリクス可視化

#### 3. 開発効率の向上
- **Hook設定**: 新プロジェクト追加時1行YAML変更のみ
- **違反対応**: 教育的ブロックメッセージによる自己解決促進
- **品質監視**: HTML ダッシュボードによる状況把握時間短縮

### 潜在的な負の影響とリスク軽減策

#### 1. 初期移行コスト
- **リスク**: 既存6スクリプトの統合・テスト工数
- **軽減策**: 段階的移行（既存並行運用 → 検証完了後切替）

#### 2. 新規依存関係
- **リスク**: yq, sqlite3, observable plot の環境依存
- **軽減策**: 依存チェック機能、フォールバック動作の実装

#### 3. 単一障害点の創出
- **リスク**: quality-gate.sh 障害時の全品質チェック停止
- **軽減策**: 緊急時バイパス機能、十分なエラーハンドリング

## Implementation Plan

### Phase 1: 基盤構築（1-2日）
1. **quality-gate.sh骨格作成**
   - Hook種別分岐ロジック実装
   - lib/helpers.sh 共通関数定義
   - 基本エラーハンドリング

2. **quality-gate.yaml設計・実装**
   - スキーマ設計（defaults/projects構造）
   - 既存閾値の移行・検証
   - yq読み込み機能実装

### Phase 2: 機能統合（2-3日）
1. **既存Hook機能統合**
   - TDD Guard → pre段階統合
   - Unused Detector → post段階統合  
   - Coverage Check → stop段階統合
   - 統合テスト・動作確認

2. **violations.jsonl ログ機能実装**
   - JSON Lines出力ロジック
   - SQLite テーブル設計・投入スクリプト
   - 基本集計クエリ作成

### Phase 3: 可視化・完成化（1-2日）
1. **KPI ダッシュボード作成**
   - SQLite → Observable Plot連携
   - HTML生成スクリプト
   - 週次バッチ・自動更新設定

2. **統合テスト・本格運用開始**
   - 全Hook動作確認
   - 既存品質基準との整合性確認
   - 旧スクリプト除去・切替完了

## Success Metrics

### 定量指標
- **Hook保守効率**: 6ファイル → 1ファイル（83%削減）
- **設定変更効率**: 閾値変更時間 90%短縮（コード変更→YAML編集）
- **違反検出精度**: 98%+（既存95%から向上）
- **ダッシュボード生成**: 5分以内の自動更新

### 定性指標
- **開発者体験**: Hook設定・カスタマイズの簡素化
- **運用自動化**: 手動違反分析→自動週次レポート
- **拡張性**: 新プロジェクト・メトリクス追加の容易性
- **可視性**: リアルタイム品質状況把握

## Related Documents

### 基盤ADR
- [ADR-003: AI完璧主義防止システム](003-ai-perfectionism-prevention-system.md) - 上位方針決定
- [ADR-004: ガバナンス統合](004-governance-integration-ai-perfectionism.md) - 統合管理体制
- [ADR-005: ドキュメント複雑性制御](005-document-complexity-control-system.md) - SQLite基盤連携

### 技術参照
- [複雑性制御アーキテクチャ](../../.claude/tmp/complexity_control_architecture.md) - アーキテクチャ背景
- [AI完璧主義防止計画](../../.claude/tmp/ai_perfectionism_prevention_plan.md) - 改善戦略A,B,E,F

### 実装文書（作成予定）
- [統合品質ガードシステム技術仕様](../../.claude/docs/04_reference/integrated_quality_gate_system.md)
- [Hook統合実装チェックリスト](../../.claude/docs/03_operations/hook_integration_checklist.md)

## Review

### レビュー計画
- **1週間後**: Phase 1-2実装状況・基本動作確認
- **2週間後**: Phase 3完了・効果測定開始
- **1ヶ月後**: 定量・定性指標評価、必要調整の実施
- **3ヶ月後**: 長期効果確認、次期拡張検討

### 成功判定基準
- **技術統合**: 全Hook機能の単一スクリプト化完了
- **設定外部化**: YAML変更のみでの全プロジェクト対応
- **自動化実現**: 週次違反分析レポートの自動生成
- **可視化提供**: HTML ダッシュボードによるリアルタイム監視

---

*このADRは、AI完璧主義防止システム（ADR-003）の技術基盤強化を目的とし、Hook複雑性削減・運用自動化・品質可視化の統合実現を決定するものです。*