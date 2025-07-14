# ドキュメント複雑性監視運用手順

> **目的**: ADR-005で決定されたドキュメント複雑性制御システムの日常運用における実践的なガイドライン

## 📋 運用概要

### 基本方針
- **段階的導入**: Week 1-6の計画的実装
- **既存システム統合**: AI完璧主義防止・継続改善システムとの連携
- **最小コスト運用**: Markdown一次ソース維持、SQLite補助的活用

### 複雑性制御の3原則
1. **予防的制約**: Front-Matter標準化によるメタデータ統一
2. **自動検出**: CI統合による品質違反の早期発見
3. **継続改善**: SQLite統合による横断分析・改善追跡

---

## 🔄 日常運用フロー

### 新規ドキュメント作成時

#### 1. Front-Matter必須チェック
```yaml
---
title: "ドキュメントタイトル"
adr: "005"  # 関連ADR（該当する場合）
status: "draft"  # draft | active | deprecated
tags: ["governance", "complexity"]
category: "operations"  # operations | reference | templates | quickstart
created: "2025-07-14"
updated: "2025-07-14"
---
```

#### 2. 複雑性事前チェック
```bash
# ドキュメント行数確認
wc -l new_document.md

# 500行超の場合は分割検討
if [[ $(wc -l < new_document.md) -gt 500 ]]; then
    echo "⚠️ 500行超過。分割を検討してください"
fi
```

#### 3. 内部リンク整合性確認
```bash
# 未解決リンクの検出
grep -o '\[.*\](.*\.md)' new_document.md | while read link; do
    file=$(echo "$link" | sed 's/.*](\(.*\))/\1/')
    if [[ ! -f "$file" ]]; then
        echo "❌ 未解決リンク: $link"
    fi
done
```

### 既存ドキュメント更新時

#### 1. Front-Matter更新
```yaml
# 更新日の自動更新
updated: "$(date +%Y-%m-%d)"

# 必要に応じてステータス変更
status: "active"  # draft → active
```

#### 2. 複雑性監視
```bash
# 行数増加の確認
git diff --stat | grep -E "\+.*lines"

# 大幅増加時は分割検討
if [[ $added_lines -gt 200 ]]; then
    echo "⚠️ 200行以上追加。分割または簡素化を検討"
fi
```

---

## 📊 Week別実装スケジュール

### Week 1: Inventory & Analysis（実装中）

#### 実施内容
- [x] **ADR-005作成**: ガバナンス手続き完了
- [x] **decision_log.md更新**: 決定事項記録
- [ ] **doc_inventory.py実装**: ドキュメント棚卸スクリプト

#### 棚卸スクリプト仕様
```python
# scripts/doc_inventory.py
import os
import re
from pathlib import Path

def analyze_documents():
    """全Markdownファイルの複雑性を分析"""
    results = []
    
    for md_file in Path('.').rglob('*.md'):
        with open(md_file, 'r', encoding='utf-8') as f:
            content = f.read()
            
        analysis = {
            'file': str(md_file),
            'lines': len(content.splitlines()),
            'links': len(re.findall(r'\[.*?\]\(.*?\.md\)', content)),
            'has_frontmatter': content.startswith('---'),
            'last_modified': md_file.stat().st_mtime
        }
        results.append(analysis)
    
    return results
```

#### Week 1成果指標
- **全Markdownファイル棚卸完了**: CSV出力で現状把握
- **複雑性ホットスポット特定**: 500行超・リンク10個超のファイル特定
- **Front-Matter適用優先度**: 主要ガバナンス文書の優先順位決定

### Week 2: Front-Matter標準化

#### 実施内容
- [ ] **JSON Schema設計**: `schemas/md-meta.schema.json`
- [ ] **主要文書への適用**: ADR・ガバナンス文書優先
- [ ] **テンプレート更新**: `.claude/docs/02_templates/` の標準化

#### 標準化対象ファイル
```
優先度高:
- governance/adr/*.md
- governance/decision_log.md
- .claude/docs/*/README.md

優先度中:
- 運用ガイド（03_operations/）
- 技術リファレンス（04_reference/）

優先度低:
- テンプレート（02_templates/）
- プロジェクト固有文書
```

#### Week 2成果指標
- **JSON Schema完成**: 必須・任意フィールド定義
- **主要文書 Front-Matter適用**: 20+ファイルに統一YAML追加
- **テンプレート更新**: 新規作成時の自動Front-Matter付与

### Week 3: CI統合・自動検証

#### 実施内容
- [ ] **GitHub Actions統合**: `.github/workflows/docs-ci.yml`
- [ ] **remark-lint設定**: Front-Matterスキーマ検証
- [ ] **リンクチェック自動化**: 内部リンク整合性検証

#### CI設定例
```yaml
# .github/workflows/docs-ci.yml
name: Documentation Quality Check

on: [push, pull_request]

jobs:
  docs-lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      
      - name: Install dependencies
        run: |
          npm install -g remark-cli remark-lint-frontmatter-schema
      
      - name: Front-Matter Schema Validation
        run: |
          remark . --use remark-lint-frontmatter-schema=schemas/md-meta.schema.json
      
      - name: Internal Link Check
        run: |
          find . -name "*.md" -exec grep -l "\[.*\](.*\.md)" {} \; | \
          xargs python scripts/link_checker.py
```

### Week 4: SQLite統合・横断検索

#### 実施内容
- [ ] **build_docs_db.py実装**: Front-Matter → SQLite抽出
- [ ] **既存KPI基盤統合**: `docs_index`テーブル追加
- [ ] **横断検索機能**: タグ・カテゴリベースクエリ

#### SQLiteスキーマ設計
```sql
-- docs_index テーブル
CREATE TABLE docs_index (
    id INTEGER PRIMARY KEY,
    file_path TEXT UNIQUE,
    title TEXT,
    adr TEXT,
    status TEXT,
    tags TEXT,  -- JSON array as text
    category TEXT,
    created DATE,
    updated DATE,
    lines INTEGER,
    internal_links INTEGER
);

-- クエリ例
SELECT * FROM docs_index 
WHERE status = 'active' 
  AND category = 'governance'
  AND tags LIKE '%complexity%'
ORDER BY updated DESC;
```

### Week 5-6: 可視化・知識グラフ（任意）

#### MkDocs統合
```yaml
# mkdocs.yml
site_name: Claude Code Workspace Documentation
nav:
  - Home: index.md
  - Governance: governance/
  - Operations: .claude/docs/03_operations/
  - Reference: .claude/docs/04_reference/

plugins:
  - search
  - tags
  - git-revision-date-localized

theme:
  name: material
  features:
    - navigation.instant
    - search.highlight
```

---

## 🔧 トラブルシューティング

### よくある問題と対処法

#### Front-Matter形式エラー
```bash
# YAML形式チェック
python -c "import yaml; yaml.safe_load(open('doc.md').read().split('---')[1])"

# エラー時の修正例
# - 不正: `tags: governance, complexity`
# + 正常: `tags: ["governance", "complexity"]`
```

#### 大量ドキュメント作成の検出
```bash
# constitution-guard.sh による自動検出
if [[ $file_count -gt 5 ]]; then
    echo "🚫 大量ドキュメント作成検出: $file_count ファイル"
    echo "ADR-005: ドキュメント複雑性制御に従い、分割または統合を検討してください"
    exit 2
fi
```

#### SQLite統合エラー
```bash
# データベース整合性チェック
sqlite3 docs_index.db "PRAGMA integrity_check;"

# Front-Matter抽出エラー確認
python scripts/build_docs_db.py --dry-run --verbose
```

---

## 📈 効果測定・KPI

### 定量指標

#### ドキュメント品質指標
```sql
-- 平均ドキュメント行数
SELECT AVG(lines) as avg_lines FROM docs_index;

-- Front-Matter適用率
SELECT 
    COUNT(CASE WHEN title IS NOT NULL THEN 1 END) * 100.0 / COUNT(*) 
    as frontmatter_coverage 
FROM docs_index;

-- カテゴリ別分布
SELECT category, COUNT(*) as count 
FROM docs_index 
GROUP BY category;
```

#### 複雑性制御効果
```bash
# Week 1 vs Week 6 比較
echo "Week 1 Baseline:"
python scripts/doc_inventory.py --baseline

echo "Week 6 Current:"
python scripts/doc_inventory.py --current

# 改善率計算
python scripts/complexity_trend.py
```

### 定性指標

#### 開発者体験指標
- **ドキュメント発見時間**: 手動検索 vs SQLiteクエリ
- **メタデータ整合性**: CI自動検証による人為ミス削減
- **知識共有効率**: 構造化情報による学習支援

#### 運用改善指標
- **CI実行時間**: 2分以内維持
- **リンク切れ検出**: 自動検出による品質向上
- **ガバナンス遵守**: ADR・decision_log の同期精度

---

## 🔗 関連システムとの連携

### AI完璧主義防止システム（ADR-003）
```bash
# constitution-guard.sh での統合チェック
if detect_bulk_document_creation; then
    echo "ドキュメント複雑性制御（ADR-005）に従い、以下を確認："
    echo "1. Front-Matter付与済み？"
    echo "2. 適切なカテゴリ分類？"
    echo "3. 500行以下に分割可能？"
fi
```

### 継続改善システム（ADR-002）
```yaml
# improvement_recommendations.md への統合
improvements:
  - id: "DOC-001"
    category: "Document Complexity"
    description: "Front-Matter標準化の完了率向上"
    priority: "medium"
    implementation: "schemas/md-meta.schema.json の必須フィールド拡張"
```

### Phase 6継続改善との統合
- **定期検証**: 月次でドキュメント複雑性KPI確認
- **改善追跡**: SQLite統合による定量的効果測定
- **プロセス改善**: Week 1-6実装結果を基にした運用最適化

---

## 📋 チェックリスト

### 日次チェック
- [ ] 新規作成ドキュメントにFront-Matter付与
- [ ] 500行超過ファイルの分割検討
- [ ] 内部リンク整合性確認

### 週次チェック
- [ ] SQLiteデータベース更新実行
- [ ] 複雑性KPI確認・トレンド分析
- [ ] CI失敗件数・原因分析

### 月次チェック
- [ ] Front-Matter適用率測定
- [ ] ドキュメント品質トレンド分析
- [ ] ADR-005実装計画進捗確認

---

*この運用手順は、ADR-005で決定されたドキュメント複雑性制御システムの実装・運用を支援し、既存のAI完璧主義防止・継続改善システムとの統合により、包括的な品質管理を実現します。*

*作成日: 2025-07-14*  
*次回更新: Week 3 CI統合完了時*