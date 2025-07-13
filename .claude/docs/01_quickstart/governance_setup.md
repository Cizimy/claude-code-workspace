# 🏛️ ガバナンス設定 (Day 3-4)

> **目標**: 議事録管理と意思決定記録の仕組みを整備し、CI で自動チェック機能を実装

## 📋 Day 3-4: Governance（議事）レイヤ導入

### 2-1. ADR (Architecture Decision Records) 初期化
**タスク**: `governance/adr/000-choose-ai-workflow.md` で CLAUDE.md 採用決定を記録

**手順**:
```bash
# ガバナンスディレクトリ作成
mkdir -p governance/adr

# ADR テンプレート作成
cat > governance/adr/000-choose-ai-workflow.md << 'EOF'
# ADR-000: AI駆動開発ワークフローの採用

## Status
Accepted

## Context
個人/チーム開発において、Claude Code を用いた AI 駆動型の開発フローを導入する必要性が生じた。

### 課題
- 手動でのコーディング・テスト・レビューサイクルが時間を消費
- コード品質の一貫性維持が困難  
- 複数プロジェクト間での開発標準の統一が必要

### 検討した選択肢
1. **従来の手動開発** - 現状維持
2. **GitHub Copilot + 手動レビュー** - 部分的 AI 支援  
3. **Claude Code + TDD + Hook** - 完全 AI 駆動 (推奨案)

## Decision
**Claude Code + TDD + Hook による AI 駆動開発ワークフロー** を採用する。

### 理由
- **品質保証**: TDD により要件の過不足を防止
- **複雑性抑制**: YAGNI 原則で不要な実装を排除
- **自動監査**: Hook による決定論的な品質チェック
- **再現性**: 新人でも 1 時間で環境構築可能

## Consequences

### Positive
- 開発速度の大幅向上（推定 3-5x）
- コード品質の安定化
- レビュー負荷の軽減

### Negative  
- Hook・設定の初期コスト
- AI 依存によるスキル習得機会の減少リスク
- API コストの発生

### Mitigation
- Hook は段階的に導入・調整
- 定期的な手動レビューセッションを実施
- コスト監視・予算設定

## Implementation
1. `.claude/settings.json` で基本設定
2. `CLAUDE.md` でプロジェクト憲法定義
3. Hook による品質ガード実装
4. GitHub Actions での CI 統合

---
記録者: [Your Name]  
記録日: [YYYY-MM-DD]
EOF
```

**完了目安**: ADR ファイル作成

### 2-2. Decision Log 初期化
**タスク**: `governance/decision_log.md` で重要決定事項の時系列管理

**手順**:
```bash
# Decision Log 作成
cat > governance/decision_log.md << 'EOF'
# 意思決定ログ

> **目的**: 技術・プロセス・組織の重要決定事項を時系列で記録

## 決定事項一覧

| 日付 | ADR# | 決定内容 | 決定者 | 影響範囲 | 状態 |
|------|------|----------|--------|----------|------|
| YYYY-MM-DD | ADR-000 | AI駆動開発ワークフロー採用 | Team | 全プロジェクト | Active |

## 決定プロセス

### 軽微な決定 (例: ツール選択)
1. Slack/Issue で提案
2. 48時間以内の非同期レビュー
3. 反対意見なしで決定

### 重要な決定 (例: アーキテクチャ変更)
1. ADR ドラフト作成
2. チームミーティングで議論  
3. ADR 更新・承認
4. Decision Log に記録

## アーカイブ

### 過去の決定変更
- ADR-XXX が Superseded になった場合、新 ADR で理由を記録
- Decision Log の状態を "Superseded" に更新

### レビュー周期
- 四半期ごとに決定事項の有効性を確認
- 不要になった決定は "Deprecated" に変更
EOF
```

**完了目安**: 空ログファイル作成

### 2-3. CI による議事チェック追加
**タスク**: GitHub Action で `adr-tools verify` とファイル名リントを実装

**手順**:
```bash
# Governance CI ワークフロー作成
cat > .github/workflows/governance.yml << 'EOF'
name: Governance CI

on:
  push:
    paths:
      - 'governance/**'
  pull_request:
    paths:
      - 'governance/**'

jobs:
  adr-validation:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install adr-tools
        run: |
          sudo apt-get update
          sudo apt-get install -y adr-tools
      
      - name: Validate ADR format
        run: |
          cd governance
          # ADR 番号の重複チェック
          ls adr/*.md | sed 's/.*\/\([0-9]*\)-.*/\1/' | sort | uniq -d | grep . && exit 1 || true
          
          # ADR メタデータ必須フィールドチェック
          for file in adr/*.md; do
            echo "Checking $file..."
            grep -q "^## Status" "$file" || (echo "Missing Status in $file" && exit 1)
            grep -q "^## Context" "$file" || (echo "Missing Context in $file" && exit 1)  
            grep -q "^## Decision" "$file" || (echo "Missing Decision in $file" && exit 1)
          done

  file-naming-lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Check ADR naming convention
        run: |
          # ADR ファイル名: NNN-kebab-case.md
          find governance/adr -name "*.md" | while read file; do
            basename="$(basename "$file")"
            if ! echo "$basename" | grep -E '^[0-9]{3}-[a-z0-9-]+\.md$'; then
              echo "ERROR: ADR naming violation: $basename"
              echo "Expected format: NNN-kebab-case.md"
              exit 1
            fi
          done
          
      - name: Check decision log format
        run: |
          if [ -f governance/decision_log.md ]; then
            # テーブル形式の確認
            grep -q "| 日付 | ADR# | 決定内容 |" governance/decision_log.md || \
              (echo "decision_log.md table format error" && exit 1)
          fi

  governance-links:
    runs-on: ubuntu-latest  
    steps:
      - uses: actions/checkout@v4
      
      - name: Validate internal links
        run: |
          # ADR 間の相互参照リンクチェック
          find governance -name "*.md" -exec grep -l "ADR-[0-9]" {} \; | while read file; do
            grep -o "ADR-[0-9][0-9][0-9]" "$file" | while read adr_ref; do
              adr_num=$(echo "$adr_ref" | sed 's/ADR-//')
              if [ ! -f "governance/adr/${adr_num}-"*.md ]; then
                echo "ERROR: Broken ADR reference $adr_ref in $file"
                exit 1
              fi
            done
          done
EOF

# Governance 専用の依存関係
cat > governance/requirements.txt << 'EOF'
# Governance tools
markdown-link-check==3.11.2
EOF
```

**完了目安**: CI green

---

## 🔧 高度な設定（オプション）

### ADR Tools の活用
```bash
# adr-tools をローカルにインストール (macOS)
brew install adr-tools

# 新しい ADR 作成
cd governance
adr new "Claude Hook 設計方針"
# → 001-claude-hook-設計方針.md が自動生成

# ADR の状態変更
adr link 001 Supersedes 000  # ADR-001 が ADR-000 を置き換え
```

### Decision Log 自動更新
```bash
# Git Hook で ADR 変更時に Decision Log を自動更新
cat > .git/hooks/post-commit << 'EOF'
#!/bin/bash
if git diff --name-only HEAD~1 | grep -q "governance/adr/"; then
  echo "ADR 変更を検出。Decision Log の更新を確認してください。"
fi
EOF
chmod +x .git/hooks/post-commit
```

### Meeting Minutes テンプレート
```bash
mkdir -p governance/mtg_minutes

# ミーティング議事録テンプレート
cat > governance/mtg_minutes/YYYY-MM-DD-template.md << 'EOF'
# Team Sync - YYYY-MM-DD

## 参加者
- [Name1]
- [Name2]

## アジェンダ
1. 前回の Action Items レビュー
2. 技術的な議論項目
3. 新規 ADR 提案

## 決定事項
| 項目 | 決定内容 | 担当者 | 期限 |
|------|----------|--------|------|
|      |          |        |      |

## Action Items
| タスク | 担当者 | 期限 | 状態 |
|--------|--------|------|------|
|        |        |      |      |

## 次回ミーティング
- 日時: 
- 場所:
- 主要議題:
EOF
```

---

## ✅ 完了チェックリスト

### ADR セットアップ
- [ ] `governance/adr/` ディレクトリ作成
- [ ] ADR-000 (AI ワークフロー採用) 作成
- [ ] ADR テンプレート準備

### Decision Log
- [ ] `governance/decision_log.md` 初期化
- [ ] 決定プロセスの文書化
- [ ] レビュー周期の設定

### CI 統合
- [ ] `governance.yml` ワークフロー作成
- [ ] ADR 形式検証の実装
- [ ] ファイル名リントの実装
- [ ] 内部リンクチェックの実装

### 動作テスト
```bash
# ADR 形式チェック
grep -E "^## (Status|Context|Decision)" governance/adr/000-*.md

# CI テスト実行
gh workflow run governance.yml

# リンクチェック
find governance -name "*.md" -exec markdown-link-check {} \;
```

**次のステップ**: [プロジェクト設定](project_setup.md)