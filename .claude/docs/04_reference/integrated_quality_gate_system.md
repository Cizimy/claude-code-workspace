# 統合品質ガードシステム技術仕様

> **目的**: ADR-006で決定された統合品質ガードシステムの詳細技術仕様とリファレンス実装

## 📋 ドキュメント概要

### 対象者
- 技術実装担当者
- Hook システム開発者  
- 品質システム運用担当者

### 前提条件
- [ADR-006: 統合品質ガードシステム技術決定](../../../governance/adr/006-integrated-quality-guard-system.md)
- Claude Code Hooks システムの基本理解
- YAML・SQLite・Bash スクリプトの基本知識

---

## 🏗️ 1. システムアーキテクチャ

### 1.1 統合アーキテクチャ概要

```
Claude Code Tool Request
        ↓
    PreToolUse Hook
    ┌─────────────────┐
    │ quality-gate.sh │ ←── quality-gate.yaml
    │ (pre)           │
    └─────────────────┘
        ↓ (if passed)
    Tool Execution
        ↓
    PostToolUse Hook  
    ┌─────────────────┐
    │ quality-gate.sh │ ←── quality-gate.yaml
    │ (post)          │
    └─────────────────┘
        ↓
    Session Complete
        ↓
    Stop Hook
    ┌─────────────────┐
    │ quality-gate.sh │ ←── violations.jsonl
    │ (stop)          │     ↓
    └─────────────────┘     SQLite DB
                              ↓
                        quality_dashboard.html
```

### 1.2 コンポーネント構成

| コンポーネント | ファイル | 役割 | 依存関係 |
|---------------|---------|------|----------|
| **統合実行エンジン** | `quality-gate.sh` | Hook統合・フェーズ分岐・実行制御 | lib/helpers.sh |
| **共通ライブラリ** | `lib/helpers.sh` | 共通関数・ユーティリティ | yq, sqlite3 |
| **設定管理** | `quality-gate.yaml` | 閾値・プロジェクト別設定 | - |
| **違反ログ** | `violations.jsonl` | 構造化違反履歴 | quality.db |
| **メトリクスDB** | `quality.db` | SQLite統合メトリクス | - |
| **ダッシュボード** | `dashboard_generator.js` | HTML可視化生成 | Observable Plot |

---

## ⚙️ 2. 実装仕様詳細

### 2.1 統合実行エンジン: quality-gate.sh

#### 基本構造
```bash
#!/bin/bash
# quality-gate.sh - 統合品質ガードシステム

set -euo pipefail

# 共通ライブラリ読み込み
source "$(dirname "$0")/lib/helpers.sh"

# Hook入力解析
HOOK_PHASE="${1:-unknown}"
HOOK_INPUT="${2:-}"

# 設定読み込み
load_config_from_yaml

# フェーズ別分岐実行
case "$HOOK_PHASE" in
    pre)
        check_tdd_compliance "$HOOK_INPUT"
        check_constitution_compliance "$HOOK_INPUT"
        ;;
    post)
        check_unused_code "$HOOK_INPUT"
        log_violations "$HOOK_INPUT"
        ;;
    stop)
        check_coverage_threshold
        generate_reports
        analyze_violations
        ;;
    *)
        error "Unknown hook phase: $HOOK_PHASE"
        exit 1
        ;;
esac
```

#### 入力・出力仕様
**入力**:
- `$1`: Hook フェーズ (`pre`|`post`|`stop`)
- `$2`: Hook入力JSON (stdin からも受け取り可能)
- 環境変数: `CLAUDE_PROJECT_ROOT`, `CLAUDE_WORKSPACE_ROOT`

**出力**:
- **exit 0**: 品質チェック通過（処理継続）
- **exit 2**: 品質チェック違反（ツール実行ブロック）
- **stderr**: 教育的メッセージ（Claudeへフィードバック）
- **stdout**: 実行ログ・メトリクス

### 2.2 共通ライブラリ: lib/helpers.sh

#### 設定管理関数
```bash
# YAML設定ファイル読み込み
load_config_from_yaml() {
    local config_file="${CLAUDE_WORKSPACE_ROOT}/.claude/hooks/quality-gate.yaml"
    
    if [[ ! -f "$config_file" ]]; then
        error "Configuration file not found: $config_file"
        exit 1
    fi
    
    # プロジェクト特定
    local project_name
    project_name=$(detect_project_from_path "$PWD")
    
    # デフォルト設定読み込み
    MAX_LINES=$(yq eval '.defaults.max_lines // 500' "$config_file")
    COVERAGE_THRESHOLD=$(yq eval '.defaults.coverage_threshold // 60' "$config_file")
    MAX_FILES_CREATION=$(yq eval '.defaults.max_files_creation // 5' "$config_file")
    
    # プロジェクト固有設定で上書き
    if [[ -n "$project_name" ]]; then
        MAX_LINES=$(yq eval ".projects.${project_name}.max_lines // $MAX_LINES" "$config_file")
        COVERAGE_THRESHOLD=$(yq eval ".projects.${project_name}.coverage_threshold // $COVERAGE_THRESHOLD" "$config_file")
    fi
}

# プロジェクト自動検出
detect_project_from_path() {
    local path="$1"
    case "$path" in
        *danbouru_advanced_wildcard*) echo "danbouru_advanced_wildcard" ;;
        *pdi*) echo "pdi" ;;
        *) echo "workspace" ;;
    esac
}
```

#### 品質チェック関数
```bash
# TDD準拠チェック
check_tdd_compliance() {
    local input="$1"
    local file_path
    file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')
    
    if [[ -z "$file_path" ]]; then
        return 0  # ファイルパス不明時はスキップ
    fi
    
    # 実装ファイル判定
    if is_implementation_file "$file_path"; then
        if ! has_recent_test_changes; then
            output_educational_block "TDD_VIOLATION" \
                "テストコードの変更なしに実装ファイルを変更しようとしています" \
                "対応するテストファイルを先に作成・更新してください" \
                "例: pytest tests/test_$(basename "$file_path" .py).py"
            exit 2
        fi
    fi
}

# 憲法準拠チェック  
check_constitution_compliance() {
    local input="$1"
    local tool_name
    tool_name=$(echo "$input" | jq -r '.tool_name // empty')
    
    if [[ "$tool_name" == "MultiEdit" ]]; then
        local file_count
        file_count=$(echo "$input" | jq -r '.tool_input.edits | length')
        
        if (( file_count > MAX_FILES_CREATION )); then
            output_educational_block "MASS_CREATION_VIOLATION" \
                "${file_count}ファイルの同時作成はAI完璧主義症候群の兆候です" \
                "作業を小分けし、必要最小限のファイル（${MAX_FILES_CREATION}ファイル以下）のみ作成してください" \
                "YAGNI原則: 今すぐ必要なもののみ実装する"
            exit 2
        fi
    fi
}
```

#### 違反ログ管理
```bash
# 構造化違反ログ出力
log_violation() {
    local violation_type="$1"
    local file_path="$2"
    local context="$3"
    
    local log_entry
    log_entry=$(jq -n \
        --arg timestamp "$(date -Iseconds)" \
        --arg type "$violation_type" \
        --arg file "$file_path" \
        --arg context "$context" \
        --arg project "$(detect_project_from_path "$PWD")" \
        '{
            timestamp: $timestamp,
            violation_type: $type,
            file_path: $file,
            context: $context,
            project: $project
        }')
    
    echo "$log_entry" >> "${CLAUDE_WORKSPACE_ROOT}/logs/violations.jsonl"
}

# 教育的ブロックメッセージ出力
output_educational_block() {
    local violation_type="$1"
    local cause="$2"
    local solution="$3"
    local example="$4"
    
    cat >&2 <<EOF
🚫 **${violation_type}**

**原因**: ${cause}

**対処**: ${solution}

**再試行**: ${example}

詳細: CLAUDE.md の AI完璧主義症候群対策を確認してください
EOF
    
    # 違反ログも記録
    log_violation "$violation_type" "${file_path:-unknown}" "$cause"
}
```

### 2.3 設定管理: quality-gate.yaml

#### スキーマ仕様
```yaml
# quality-gate.yaml スキーマ
defaults:
  max_lines: 500                    # 1ファイルあたりの最大行数
  coverage_threshold: 60            # 最小テストカバレッジ（%）
  max_files_creation: 5             # 同時作成可能ファイル数上限
  
  # 教育的ブロック設定
  educational_block_enabled: true
  constitution_reminder_interval: 20 # N回ツール実行毎にリマインド
  
  # ログ・レポート設定  
  violations_log: "logs/violations.jsonl"
  quality_db: "logs/quality.db"
  dashboard_output: "quality_dashboard.html"

# プロジェクト固有設定（defaults を継承・上書き）
projects:
  danbouru_advanced_wildcard:
    coverage_threshold: 80
    max_lines: 300
    test_framework: "pytest"
    test_command: "pytest --cov=src --cov-report=term-missing"
    
  pdi:
    coverage_threshold: 70
    max_lines: 600
    test_framework: "manual"
    constitution_checks_relaxed: true  # VBA 言語制約による緩和
    
  workspace:
    coverage_threshold: 50
    test_framework: "none"
    constitution_checks_enabled: false # ワークスペース設定は除外

# Hook別個別設定
hooks:
  pre_tool:
    enabled_checks: ["tdd", "constitution", "file_size"]
    
  post_tool:
    enabled_checks: ["unused_code", "style"]
    tools: ["vulture", "ruff"]
    
  stop:
    enabled_checks: ["coverage", "violations_analysis"]
    report_generation: true
```

### 2.4 違反ログ: violations.jsonl

#### JSON Lines形式仕様
```jsonl
{"timestamp":"2025-07-14T10:30:00+00:00","violation_type":"TDD_VIOLATION","file_path":"src/main.py","context":"テスト変更なしの実装変更","project":"danbouru_advanced_wildcard"}
{"timestamp":"2025-07-14T11:15:00+00:00","violation_type":"MASS_CREATION_VIOLATION","file_path":"bulk_create","context":"7ファイル同時作成","project":"workspace"}
{"timestamp":"2025-07-14T14:22:00+00:00","violation_type":"COVERAGE_VIOLATION","file_path":"src/analyzer.py","context":"カバレッジ 75% < 80% 基準","project":"danbouru_advanced_wildcard"}
```

#### SQLiteテーブル設計
```sql
-- quality.db schema
CREATE TABLE violations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp TEXT NOT NULL,
    violation_type TEXT NOT NULL,
    file_path TEXT,
    context TEXT,
    project TEXT,
    resolved BOOLEAN DEFAULT FALSE,
    resolution_note TEXT
);

CREATE TABLE coverage_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp TEXT NOT NULL,
    project TEXT NOT NULL,
    coverage_percentage REAL NOT NULL,
    total_lines INTEGER,
    covered_lines INTEGER
);

CREATE TABLE metrics_summary (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date TEXT NOT NULL,
    project TEXT NOT NULL,
    violation_count INTEGER DEFAULT 0,
    avg_coverage REAL,
    files_created INTEGER DEFAULT 0,
    hook_executions INTEGER DEFAULT 0
);

-- インデックス
CREATE INDEX idx_violations_timestamp ON violations(timestamp);
CREATE INDEX idx_violations_project ON violations(project);
CREATE INDEX idx_violations_type ON violations(violation_type);
```

---

## 📊 3. KPI ダッシュボード仕様

### 3.1 dashboard_generator.js 実装

#### Observable Plot 統合
```javascript
#!/usr/bin/env node
// dashboard_generator.js - 軽量KPIダッシュボード生成

const Plot = require("@observablehq/plot");
const sqlite3 = require("sqlite3");
const fs = require("fs");

class QualityDashboard {
    constructor(dbPath) {
        this.db = new sqlite3.Database(dbPath);
    }
    
    async generateHTML() {
        const violations = await this.getViolationsData();
        const coverage = await this.getCoverageData();
        
        const violationsChart = Plot.plot({
            title: "Violations by Type (Last 30 Days)",
            x: {label: "Date"},
            y: {label: "Count"},
            marks: [
                Plot.barY(violations, {x: "date", y: "count", fill: "violation_type"}),
                Plot.ruleY([0])
            ]
        });
        
        const coverageChart = Plot.plot({
            title: "Coverage Trend",
            x: {label: "Date"},
            y: {label: "Coverage %"},
            marks: [
                Plot.lineY(coverage, {x: "date", y: "coverage", stroke: "project"}),
                Plot.ruleY([60], {stroke: "red", strokeDasharray: "5,5"}) // 最小基準線
            ]
        });
        
        const html = `
<!DOCTYPE html>
<html>
<head>
    <title>Quality Dashboard - Claude Code Workspace</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .chart { margin: 20px 0; }
        .summary { display: flex; gap: 20px; margin-bottom: 30px; }
        .metric { padding: 15px; border: 1px solid #ddd; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>Claude Code Workspace - Quality Dashboard</h1>
    <p>Generated: ${new Date().toISOString()}</p>
    
    <div class="summary">
        ${await this.generateSummaryCards()}
    </div>
    
    <div class="chart">${violationsChart}</div>
    <div class="chart">${coverageChart}</div>
    
    <h2>Recent Violations</h2>
    ${await this.generateViolationsTable()}
</body>
</html>`;
        
        fs.writeFileSync("quality_dashboard.html", html);
        console.log("Dashboard generated: quality_dashboard.html");
    }
    
    async getViolationsData() {
        return new Promise((resolve, reject) => {
            this.db.all(`
                SELECT 
                    DATE(timestamp) as date,
                    violation_type,
                    COUNT(*) as count
                FROM violations 
                WHERE timestamp > date('now', '-30 days')
                GROUP BY DATE(timestamp), violation_type
                ORDER BY date
            `, (err, rows) => {
                if (err) reject(err);
                else resolve(rows);
            });
        });
    }
    
    async getCoverageData() {
        return new Promise((resolve, reject) => {
            this.db.all(`
                SELECT 
                    DATE(timestamp) as date,
                    project,
                    AVG(coverage_percentage) as coverage
                FROM coverage_history 
                WHERE timestamp > date('now', '-30 days')
                GROUP BY DATE(timestamp), project
                ORDER BY date
            `, (err, rows) => {
                if (err) reject(err);
                else resolve(rows);
            });
        });
    }
    
    async generateSummaryCards() {
        const stats = await this.getSummaryStats();
        return `
            <div class="metric">
                <h3>Total Violations (7 days)</h3>
                <p>${stats.violations_week}</p>
            </div>
            <div class="metric">
                <h3>Average Coverage</h3>
                <p>${stats.avg_coverage}%</p>
            </div>
            <div class="metric">
                <h3>Hook Executions (7 days)</h3>
                <p>${stats.hook_executions}</p>
            </div>
        `;
    }
}

// メイン実行
const dashboard = new QualityDashboard("logs/quality.db");
dashboard.generateHTML().catch(console.error);
```

### 3.2 週次分析バッチ: analyze_violations.sh

```bash
#!/bin/bash
# analyze_violations.sh - 週次違反分析・改善提案

set -euo pipefail

QUALITY_DB="${CLAUDE_WORKSPACE_ROOT}/logs/quality.db"
REPORT_OUTPUT="${CLAUDE_WORKSPACE_ROOT}/logs/weekly_analysis.md"

# 頻出違反パターン分析
echo "# Weekly Quality Analysis - $(date +'%Y-%m-%d')" > "$REPORT_OUTPUT"
echo "" >> "$REPORT_OUTPUT"

echo "## Top Violations (Last 7 Days)" >> "$REPORT_OUTPUT"
sqlite3 "$QUALITY_DB" -header -markdown "
SELECT 
    violation_type,
    COUNT(*) as frequency,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) as percentage
FROM violations 
WHERE timestamp > date('now', '-7 days')
GROUP BY violation_type
ORDER BY frequency DESC
LIMIT 5
" >> "$REPORT_OUTPUT"

echo "" >> "$REPORT_OUTPUT"
echo "## Recommendations" >> "$REPORT_OUTPUT"

# 改善提案生成
sqlite3 "$QUALITY_DB" "
SELECT violation_type, COUNT(*) as count
FROM violations 
WHERE timestamp > date('now', '-7 days')
GROUP BY violation_type
ORDER BY count DESC
LIMIT 3
" | while IFS='|' read -r violation_type count; do
    case "$violation_type" in
        "TDD_VIOLATION")
            echo "- **TDD Compliance**: $count violations detected. Consider setting up pre-commit hooks for automatic test verification." >> "$REPORT_OUTPUT"
            ;;
        "MASS_CREATION_VIOLATION")
            echo "- **AI Perfectionism**: $count mass creation attempts. Review CLAUDE.md perfectionism guidelines." >> "$REPORT_OUTPUT"
            ;;
        "COVERAGE_VIOLATION")
            echo "- **Test Coverage**: $count coverage failures. Focus on increasing test coverage in frequently modified files." >> "$REPORT_OUTPUT"
            ;;
    esac
done

# Slack通知（オプション）
if [[ -n "${SLACK_WEBHOOK_URL:-}" ]]; then
    curl -X POST -H 'Content-type: application/json' \
        --data "{'text':'Weekly Quality Analysis Report generated'}" \
        "$SLACK_WEBHOOK_URL"
fi

echo "Weekly analysis complete: $REPORT_OUTPUT"
```

---

## 🔧 4. 実装・デプロイメント

### 4.1 ファイル配置構造
```
.claude/
├── hooks/
│   ├── quality-gate.sh              # 統合実行エンジン
│   ├── quality-gate.yaml           # 設定ファイル
│   ├── lib/
│   │   └── helpers.sh               # 共通ライブラリ
│   └── scripts/
│       ├── dashboard_generator.js   # ダッシュボード生成
│       └── analyze_violations.sh    # 週次分析バッチ
├── settings.json                    # Hook設定（既存更新）
└── logs/
    ├── violations.jsonl             # 違反ログ
    ├── quality.db                   # SQLite DB
    └── weekly_analysis.md            # 週次レポート
```

### 4.2 .claude/settings.json 更新

```json
{
  "tools": {
    "allow": ["Read", "Write", "Edit", "MultiEdit", "Bash", "LS", "Glob", "Grep"],
    "deny": ["WebFetch"]
  },
  "hooks": {
    "PreToolUse": [{
      "matcher": "Edit|MultiEdit",
      "hooks": [{
        "type": "command",
        "command": ".claude/hooks/quality-gate.sh pre"
      }]
    }],
    "PostToolUse": [{
      "matcher": "Edit|MultiEdit",
      "hooks": [{
        "type": "command", 
        "command": ".claude/hooks/quality-gate.sh post"
      }]
    }],
    "Stop": [{
      "hooks": [{
        "type": "command",
        "command": ".claude/hooks/quality-gate.sh stop"
      }]
    }]
  }
}
```

### 4.3 依存関係インストール

```bash
# システム依存関係
sudo apt-get install -y yq sqlite3    # Ubuntu/Debian
brew install yq sqlite3               # macOS

# Node.js 依存関係（ダッシュボード用）
npm install -g @observablehq/plot sqlite3

# 権限設定
chmod +x .claude/hooks/quality-gate.sh
chmod +x .claude/hooks/scripts/analyze_violations.sh
```

### 4.4 初期セットアップスクリプト

```bash
#!/bin/bash
# setup_quality_system.sh - 統合品質システム初期セットアップ

set -euo pipefail

WORKSPACE_ROOT="${1:-$(pwd)}"
HOOKS_DIR="$WORKSPACE_ROOT/.claude/hooks"
LOGS_DIR="$WORKSPACE_ROOT/logs"

echo "Setting up Integrated Quality Guard System..."

# ディレクトリ作成
mkdir -p "$HOOKS_DIR/lib" "$HOOKS_DIR/scripts" "$LOGS_DIR"

# SQLite DB初期化
cat > "$LOGS_DIR/init_db.sql" <<EOF
CREATE TABLE IF NOT EXISTS violations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp TEXT NOT NULL,
    violation_type TEXT NOT NULL,
    file_path TEXT,
    context TEXT,
    project TEXT,
    resolved BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS coverage_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp TEXT NOT NULL,
    project TEXT NOT NULL,
    coverage_percentage REAL NOT NULL,
    total_lines INTEGER,
    covered_lines INTEGER
);

CREATE INDEX IF NOT EXISTS idx_violations_timestamp ON violations(timestamp);
CREATE INDEX IF NOT EXISTS idx_violations_project ON violations(project);
EOF

sqlite3 "$LOGS_DIR/quality.db" < "$LOGS_DIR/init_db.sql"
rm "$LOGS_DIR/init_db.sql"

# 週次分析のcron設定（オプション）
echo "0 9 * * 1 cd $WORKSPACE_ROOT && .claude/hooks/scripts/analyze_violations.sh" | crontab -

echo "✅ Integrated Quality Guard System setup complete!"
echo "📊 Dashboard: Run 'node .claude/hooks/scripts/dashboard_generator.js' to generate"
echo "📋 Config: Edit .claude/hooks/quality-gate.yaml for project-specific settings"
```

---

## 🔍 5. テスト・検証

### 5.1 単体テスト例

```bash
#!/bin/bash
# test_quality_gate.sh - 統合品質ガードシステムのテスト

set -euo pipefail

# テスト環境準備
export CLAUDE_WORKSPACE_ROOT="/tmp/quality_test"
mkdir -p "$CLAUDE_WORKSPACE_ROOT"/{.claude/hooks,logs}

# モックHook入力作成
create_mock_input() {
    local tool_name="$1"
    local file_path="$2"
    
    cat <<EOF
{
    "tool_name": "$tool_name",
    "tool_input": {
        "file_path": "$file_path"
    }
}
EOF
}

# TDD違反テスト
test_tdd_violation() {
    echo "Testing TDD violation detection..."
    
    local input
    input=$(create_mock_input "Edit" "src/main.py")
    
    # テスト変更なしで実装ファイル編集を試行
    if .claude/hooks/quality-gate.sh pre "$input" 2>/dev/null; then
        echo "❌ TDD violation not detected"
        return 1
    else
        echo "✅ TDD violation correctly detected"
    fi
}

# カバレッジチェックテスト
test_coverage_check() {
    echo "Testing coverage check..."
    
    # 模擬カバレッジファイル作成
    echo "TOTAL 45% coverage" > /tmp/coverage_output.txt
    
    if .claude/hooks/quality-gate.sh stop 2>/dev/null; then
        echo "❌ Coverage violation not detected"
        return 1
    else
        echo "✅ Coverage violation correctly detected"
    fi
}

# 大量作成違反テスト
test_mass_creation_violation() {
    echo "Testing mass creation violation..."
    
    local input
    input=$(cat <<EOF
{
    "tool_name": "MultiEdit",
    "tool_input": {
        "edits": [
            {"file_path": "file1.py"},
            {"file_path": "file2.py"},
            {"file_path": "file3.py"},
            {"file_path": "file4.py"},
            {"file_path": "file5.py"},
            {"file_path": "file6.py"}
        ]
    }
}
EOF
)
    
    if .claude/hooks/quality-gate.sh pre "$input" 2>/dev/null; then
        echo "❌ Mass creation violation not detected"
        return 1
    else
        echo "✅ Mass creation violation correctly detected"
    fi
}

# 全テスト実行
main() {
    echo "🧪 Running Quality Gate System Tests..."
    
    test_tdd_violation
    test_coverage_check  
    test_mass_creation_violation
    
    echo "✅ All tests passed!"
}

main "$@"
```

### 5.2 統合テスト（e2e）

```bash
#!/bin/bash
# e2e_test.sh - エンドツーエンドテスト

# 実際のClaudeCodeセッションをシミュレート
simulate_claude_session() {
    echo "🎭 Simulating Claude Code session..."
    
    # 1. TDD準拠の開発フロー
    echo "1. Creating test file first (TDD)..."
    echo 'def test_new_feature(): pass' > tests/test_new.py
    git add tests/test_new.py
    
    # 2. 実装ファイル作成（should pass）
    echo "2. Creating implementation (should pass)..."
    echo 'def new_feature(): return "hello"' > src/new.py
    
    # 3. カバレッジチェック（should trigger coverage analysis）
    echo "3. Running coverage check..."
    pytest --cov=src --cov-report=term-missing > /tmp/coverage.out
    
    # 4. ダッシュボード生成
    echo "4. Generating dashboard..."
    node .claude/hooks/scripts/dashboard_generator.js
    
    echo "✅ E2E test session complete"
    echo "📊 Check quality_dashboard.html for results"
}

simulate_claude_session
```

---

## 📚 6. 運用ガイド

### 6.1 日常運用チェックリスト

#### 開発者向け
- [ ] `.claude/hooks/quality-gate.yaml` でプロジェクト設定確認
- [ ] 違反ブロック時の教育的メッセージに従って対応
- [ ] 週次分析レポート確認・改善点の実践

#### システム管理者向け  
- [ ] `logs/violations.jsonl` のローテーション設定
- [ ] `quality.db` のバックアップ・メンテナンス
- [ ] ダッシュボード自動生成の動作確認
- [ ] Hook依存関係（yq, sqlite3）の動作確認

### 6.2 トラブルシューティング

#### よくある問題と対処法

**Q: Hook実行時に "yq: command not found" エラー**
```bash
# Ubuntu/Debian
sudo apt-get install -y yq
# macOS  
brew install yq
```

**Q: 設定変更が反映されない**
```bash
# YAML構文チェック
yq eval '.defaults' .claude/hooks/quality-gate.yaml
# Hook再読み込み（Claude Code再起動）
```

**Q: SQLite DB が破損した場合**
```bash
# バックアップから復旧
cp logs/quality.db.backup logs/quality.db
# または新規作成
rm logs/quality.db
bash .claude/hooks/scripts/setup_quality_system.sh
```

### 6.3 カスタマイズガイド

#### 新しいプロジェクト追加
```yaml
# quality-gate.yaml に追加
projects:
  my_new_project:
    coverage_threshold: 75
    max_lines: 400
    test_framework: "jest"
    test_command: "npm test -- --coverage"
```

#### 新しい違反タイプ追加
```bash
# lib/helpers.sh に追加
check_custom_rule() {
    local input="$1"
    # カスタムチェックロジック
    if [[ custom_condition ]]; then
        output_educational_block "CUSTOM_VIOLATION" \
            "Custom rule violation detected" \
            "Follow custom best practices" \
            "Example: fix command"
        exit 2
    fi
}
```

---

## 🔗 7. 関連資料

### 7.1 ADR・ガバナンス文書
- [ADR-006: 統合品質ガードシステム技術決定](../../../governance/adr/006-integrated-quality-guard-system.md)
- [ADR-003: AI完璧主義防止システム](../../../governance/adr/003-ai-perfectionism-prevention-system.md)
- [決定ログ](../../../governance/decision_log.md)

### 7.2 実装支援ドキュメント
- [Hook統合実装チェックリスト](../03_operations/hook_integration_checklist.md)
- [品質システム運用手順](../03_operations/quality_control.md)
- [AI完璧主義監視](../03_operations/ai_perfectionism_monitoring.md)

### 7.3 外部参考資料
- [Claude Code Hooks 公式ドキュメント](https://docs.anthropic.com/en/docs/claude-code/hooks)
- [Observable Plot API](https://observablehq.com/plot/)
- [yq YAML処理](https://mikefarah.gitbook.io/yq/)

---

*統合品質ガードシステム技術仕様 v1.0*  
*作成日: 2025-07-14*  
*次回レビュー: 2025-08-14*