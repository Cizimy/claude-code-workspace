# 🔍 実装検証 SOP (Standard Operating Procedure)

> **目的**: `.claude/docs/01_quickstart/README.md` の Scope に従って実装されているかを網羅的に検証するための標準作業手順書

## 📊 検証サマリーダッシュボード

### ✅ 即座確認チェックリスト (30秒)
```bash
# 1. 基本ファイル存在確認
ls .claude/settings.json .claude/hooks/*/*/*.sh governance/README.md CLAUDE.md

# 2. Git 状態確認
git status --porcelain

# 3. CI 状態確認 (GitHub Actions)
gh workflow list --all

# 4. 権限設定確認
ls -la .claude/hooks/*/*.sh | grep -E "^-rwx"
```

### 🎯 Phase 別実装完了率
| Phase | 計画完了目安 | 実装状況 | 検証ステータス |
|-------|-------------|----------|--------------|
| **Phase 1: 基盤構築** | Day 0-2 | ✅ 完了 | 要検証 |
| **Phase 2: ガバナンス整備** | Day 3-4 | ✅ 完了 | 要検証 |
| **Phase 3: プロジェクト統合** | Day 5-6 | 🔄 部分実装 | ✅ 検証完了 (70%達成) |
| **Phase 4: AI自動化** | Day 7 | ✅ 完了 | 要検証 |
| **Phase 5: 実証・運用開始** | Day 8-10 | 🔄 進行中 | 要検証 |

---

## 🔎 Phase 1: 基盤構築 検証手順

### ✅ 検証項目 1-1: 環境セットアップ完了証明

#### 必須ファイル存在確認
```bash
echo "=== Phase 1 基盤構築検証 ===" 

# 1.1 重要設定ファイル存在確認
echo "1. 設定ファイル確認..."
test -f .claude/settings.json && echo "✅ .claude/settings.json 存在" || echo "❌ .claude/settings.json 不足"
test -f CLAUDE.md && echo "✅ CLAUDE.md 存在" || echo "❌ CLAUDE.md 不足"
test -f README.md && echo "✅ README.md 存在" || echo "❌ README.md 不足"

# 1.2 Hook スクリプト実行権限確認
echo "2. Hook 実行権限確認..."
for hook_file in .claude/hooks/pre-tool/tdd-guard.sh .claude/hooks/post-tool/unused-detector.sh .claude/hooks/stop/coverage-check.sh; do
    if [ -x "$hook_file" ]; then
        echo "✅ $hook_file 実行可能"
    else
        echo "❌ $hook_file 実行権限なし"
    fi
done

# 1.3 GitHub Actions ワークフロー確認
echo "3. GitHub Actions 確認..."
test -f .github/workflows/claude.yml && echo "✅ Claude CI ワークフロー存在" || echo "❌ Claude CI 未設定"
test -f .github/workflows/governance.yml && echo "✅ Governance CI ワークフロー存在" || echo "❌ Governance CI 未設定"

# 1.4 権限設定詳細確認
echo "4. Claude Code 権限設定確認..."
if grep -q '"permissions"' .claude/settings.json; then
    echo "✅ 権限設定セクション存在"
    
    # 必須許可ツール確認
    for tool in "git" "python" "pytest" "npm" "gh"; do
        if grep -q "\"$tool\"" .claude/settings.json; then
            echo "✅ $tool 権限許可済み"
        else
            echo "⚠️  $tool 権限未設定"
        fi
    done
    
    # Hook 設定確認
    if grep -q '"hooks"' .claude/settings.json; then
        echo "✅ Hook 設定存在"
    else
        echo "❌ Hook 設定不足"
    fi
else
    echo "❌ 権限設定不足"
fi
```

#### 検証完了条件
- [ ] `.claude/settings.json` 存在・権限設定済み
- [ ] Hook スクリプト 3本すべて実行権限付き
- [ ] GitHub Actions ワークフロー 2本設定済み
- [ ] `CLAUDE.md` でプロジェクト憲法定義済み

### ✅ 検証項目 1-2: Hook システム動作確認

#### Hook 動作テスト
```bash
echo "=== Hook システム動作検証 ==="

# 1. Pre-tool Hook (TDD Guard) テスト
echo "1. TDD Guard Hook テスト..."
if .claude/hooks/pre-tool/tdd-guard.sh "Edit" "test_file.py" 2>/dev/null; then
    echo "✅ TDD Guard Hook 正常動作"
else
    exit_code=$?
    if [ $exit_code -eq 2 ]; then
        echo "✅ TDD Guard Hook 正常動作 (意図的ブロック)"
    else
        echo "❌ TDD Guard Hook 異常終了"
    fi
fi

# 2. Post-tool Hook (Unused Detector) テスト  
echo "2. Unused Detector Hook テスト..."
if command -v vulture >/dev/null 2>&1; then
    .claude/hooks/post-tool/unused-detector.sh && echo "✅ Unused Detector Hook 正常動作"
else
    echo "⚠️  vulture 未インストール - Hook機能限定的"
fi

# 3. Stop Hook (Coverage Check) テスト
echo "3. Coverage Check Hook テスト..."
if command -v pytest >/dev/null 2>&1; then
    .claude/hooks/stop/coverage-check.sh && echo "✅ Coverage Check Hook 正常動作"
else
    echo "⚠️  pytest 未インストール - Hook機能限定的"
fi

# 4. Hook 設定統合確認
echo "4. Claude Code Hook 統合確認..."
if grep -A 20 '"hooks"' .claude/settings.json | grep -q 'tdd-guard.sh'; then
    echo "✅ Pre-tool Hook 統合設定"
else
    echo "❌ Pre-tool Hook 統合未設定"
fi

if grep -A 20 '"hooks"' .claude/settings.json | grep -q 'unused-detector.sh'; then
    echo "✅ Post-tool Hook 統合設定" 
else
    echo "❌ Post-tool Hook 統合未設定"
fi

if grep -A 20 '"hooks"' .claude/settings.json | grep -q 'coverage-check.sh'; then
    echo "✅ Stop Hook 統合設定"
else
    echo "❌ Stop Hook 統合未設定"
fi
```

#### 検証完了条件
- [ ] TDD Guard Hook が実装・動作確認済み
- [ ] Unused Detector Hook が実装・動作確認済み
- [ ] Coverage Check Hook が実装・動作確認済み
- [ ] `.claude/settings.json` に Hook 統合設定済み

---

## 🏛️ Phase 2: ガバナンス整備 検証手順

### ✅ 検証項目 2-1: ADR (Architecture Decision Records) 検証

#### ADR 構造・形式確認
```bash
echo "=== Phase 2 ガバナンス整備検証 ==="

# 1. ガバナンス基本構造確認
echo "1. ガバナンス ディレクトリ構造確認..."
test -d governance/adr && echo "✅ ADR ディレクトリ存在" || echo "❌ ADR ディレクトリ不足"
test -d governance/mtg_minutes && echo "✅ 議事録ディレクトリ存在" || echo "❌ 議事録ディレクトリ不足"
test -f governance/decision_log.md && echo "✅ 意思決定ログ存在" || echo "❌ 意思決定ログ不足"
test -f governance/README.md && echo "✅ ガバナンス README 存在" || echo "❌ ガバナンス README 不足"

# 2. ADR ファイル存在・命名規則確認
echo "2. ADR ファイル確認..."
adr_count=$(find governance/adr -name "*.md" -not -name "TEMPLATE.md" 2>/dev/null | wc -l)
echo "📁 ADR ファイル数: $adr_count"

if [ $adr_count -gt 0 ]; then
    echo "ADR ファイル命名規則確認..."
    find governance/adr -name "*.md" -not -name "TEMPLATE.md" | while read file; do
        basename_file="$(basename "$file")"
        if echo "$basename_file" | grep -E '^[0-9]{3}-[a-z0-9-]+\.md$' >/dev/null; then
            echo "✅ $basename_file 命名規則適合"
        else
            echo "❌ $basename_file 命名規則違反"
        fi
    done
else
    echo "⚠️  ADR ファイルが存在しません"
fi

# 3. ADR 必須セクション確認
echo "3. ADR 形式確認..."
find governance/adr -name "*.md" -not -name "TEMPLATE.md" | while read file; do
    echo "チェック中: $file"
    
    # 必須セクション存在確認
    if grep -q "^## Status" "$file"; then
        status_value=$(grep "^## Status" -A 1 "$file" | tail -1 | xargs)
        if echo "$status_value" | grep -E "(Proposed|Accepted|Rejected|Superseded)" >/dev/null; then
            echo "✅ Status セクション正常: $status_value"
        else
            echo "⚠️  Status 値が標準外: $status_value"
        fi
    else
        echo "❌ Status セクション不足"
    fi
    
    grep -q "^## Context" "$file" && echo "✅ Context セクション存在" || echo "❌ Context セクション不足"
    grep -q "^## Decision" "$file" && echo "✅ Decision セクション存在" || echo "❌ Decision セクション不足"
    grep -q "^## Consequences" "$file" && echo "✅ Consequences セクション存在" || echo "⚠️  Consequences セクション推奨"
done
```

#### 検証完了条件
- [ ] `governance/adr/` ディレクトリ存在
- [ ] ADR-000 (Claude Code採用決定) 存在・形式適合
- [ ] ADR ファイル命名規則 (`NNN-kebab-case.md`) 遵守
- [ ] 必須セクション (Status, Context, Decision) 完備

### ✅ 検証項目 2-2: CI 自動チェック機能検証

#### Governance CI 動作確認
```bash
echo "4. Governance CI 自動チェック機能確認..."

# 1. Governance ワークフロー存在・構文確認
if [ -f .github/workflows/governance.yml ]; then
    echo "✅ Governance CI ワークフロー存在"
    
    # YAML 構文確認 (python 使用)
    if python3 -c "import yaml; yaml.safe_load(open('.github/workflows/governance.yml'))" 2>/dev/null; then
        echo "✅ Governance CI YAML 構文正常"
    else
        echo "❌ Governance CI YAML 構文エラー"
    fi
    
    # 必要なジョブ確認
    if grep -q "adr-validation:" .github/workflows/governance.yml; then
        echo "✅ ADR 検証ジョブ設定済み"
    else
        echo "❌ ADR 検証ジョブ不足"
    fi
    
    if grep -q "file-naming-lint:" .github/workflows/governance.yml; then
        echo "✅ ファイル命名規則チェックジョブ設定済み"
    else
        echo "❌ ファイル命名規則チェックジョブ不足"
    fi
    
    if grep -q "governance-links:" .github/workflows/governance.yml; then
        echo "✅ リンク検証ジョブ設定済み"
    else
        echo "❌ リンク検証ジョブ不足"
    fi
else
    echo "❌ Governance CI ワークフロー不足"
fi

# 2. CI トリガー設定確認
echo "CI トリガー設定確認..."
if grep -A 5 "^on:" .github/workflows/governance.yml | grep -q "governance/"; then
    echo "✅ governance/ パス変更時の自動実行設定済み"
else
    echo "❌ governance/ パス変更時の自動実行未設定"
fi

# 3. GitHub Actions 最新実行状況確認
echo "GitHub Actions 実行状況確認..."
if command -v gh >/dev/null 2>&1; then
    echo "最新の Governance CI 実行状況:"
    gh run list --workflow=governance.yml --limit=3 2>/dev/null || echo "⚠️  gh CLI 認証が必要または履歴なし"
else
    echo "⚠️  gh CLI 未インストール - 手動確認が必要"
fi
```

#### 検証完了条件
- [ ] `.github/workflows/governance.yml` 存在・構文正常
- [ ] ADR 形式検証ジョブ実装済み
- [ ] ファイル命名規則チェックジョブ実装済み
- [ ] governance/ 変更時の自動実行設定済み
- [ ] CI が "green" 状態 (エラーなし)

### ✅ 検証項目 2-3: Decision Log・議事録管理確認

#### Decision Log 構造確認
```bash
echo "5. Decision Log・議事録管理確認..."

# 1. Decision Log 形式確認
if [ -f governance/decision_log.md ]; then
    echo "✅ Decision Log 存在"
    
    # テーブル形式確認
    if grep -q "| 日付 | ADR" governance/decision_log.md; then
        echo "✅ Decision Log テーブル形式正常"
    else
        echo "❌ Decision Log テーブル形式異常"
    fi
    
    # ADR 参照リンク確認
    adr_refs=$(grep -o "ADR-[0-9][0-9][0-9]" governance/decision_log.md 2>/dev/null || true)
    if [ -n "$adr_refs" ]; then
        echo "ADR 参照リンク確認..."
        for adr_ref in $adr_refs; do
            adr_num=$(echo "$adr_ref" | sed 's/ADR-//')
            if ls governance/adr/${adr_num}-*.md >/dev/null 2>&1; then
                echo "✅ $adr_ref リンク有効"
            else
                echo "❌ $adr_ref リンク無効"
            fi
        done
    else
        echo "⚠️  ADR 参照リンクなし"
    fi
else
    echo "❌ Decision Log 不足"
fi

# 2. 議事録テンプレート・実績確認
if [ -d governance/mtg_minutes ]; then
    echo "✅ 議事録ディレクトリ存在"
    
    mtg_count=$(find governance/mtg_minutes -name "*.md" -not -name "TEMPLATE.md" 2>/dev/null | wc -l)
    echo "📝 議事録ファイル数: $mtg_count"
    
    if [ -f governance/mtg_minutes/TEMPLATE.md ]; then
        echo "✅ 議事録テンプレート存在"
    else
        echo "⚠️  議事録テンプレート不足"
    fi
else
    echo "❌ 議事録ディレクトリ不足"
fi
```

#### 検証完了条件
- [ ] `governance/decision_log.md` 存在・テーブル形式適合
- [ ] Decision Log 内の ADR 参照リンクが有効
- [ ] `governance/mtg_minutes/` ディレクトリ存在
- [ ] 議事録テンプレート準備済み

---

## 📦 Phase 3: プロジェクト統合 基本確認

### 統合機能確認項目
- [ ] `projects/` ディレクトリ存在
- [ ] サンプルプロジェクト基本構成完備
- [ ] プロジェクト固有 Claude 設定存在

---

## 📋 Phase 4: AI自動化 基本確認

### Claude Commands 確認項目
- [ ] `.claude/commands/project-new-feature.yml` 存在
- [ ] `.claude/commands/project-fix-bug.yml` 存在
- [ ] YAML構文エラーなし

### Hook システム統合確認
- [ ] Hook 統合設定済み
- [ ] Hook 実行権限付与済み
- [ ] Hook 動作テスト成功

---

## 📊 基本検証チェックリスト

### 必須要件確認
- [ ] `.claude/settings.json` 存在・権限設定済み
- [ ] Hook スクリプト実行権限付与済み
- [ ] GitHub Actions ワークフロー設定済み
- [ ] `CLAUDE.md` プロジェクト憲法定義済み

---

## 🎯 合格基準

**✅ 実装完了**: 必須要件すべて満たす  
**❌ 要改善**: 必須要件に不備

---

*最終更新: 2025-07-14*  
*作成者: Claude Code Implementation Verification Team*