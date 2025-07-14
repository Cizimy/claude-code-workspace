---
title: "JSON Schemas for Document Front-Matter"
status: "active"
category: "reference"
created: "2025-07-10"
updated: "2025-07-14"
tags: ["schemas", "front-matter", "validation", "adr-005"]
priority: "medium"
---

# JSON Schemas for Document Front-Matter

> **Purpose**: Schema definitions for Front-Matter validation in Claude Code workspace documents (ADR-005)

## 📋 Schema Overview

This directory contains JSON Schema definitions that enforce consistent Front-Matter structure across all Markdown documents in the workspace.

### Base Schema
- **[md-meta.schema.json](md-meta.schema.json)**: Core Front-Matter schema with common fields

### Category-Specific Schemas  
- **[governance.schema.json](governance.schema.json)**: Extended schema for ADRs and governance documents
- **[operations.schema.json](operations.schema.json)**: Extended schema for procedures and operational guides
- **[reference.schema.json](reference.schema.json)**: Extended schema for technical specifications and API docs

## 🏷️ Required Front-Matter Fields

All Markdown documents must include these mandatory fields:

```yaml
---
title: "Document Title"
status: "draft|active|deprecated|proposed|accepted|rejected|superseded"  
category: "governance|operations|reference|templates|quickstart"
created: "YYYY-MM-DD"
updated: "YYYY-MM-DD"
---
```

## 📊 Category-Specific Extensions

### Governance Documents
```yaml
---
# Base fields + governance extensions
adr: "005"                    # ADR number (3 digits)
decision_date: "2025-07-14"   # Decision date
stakeholders: ["team1", "team2"]
impact_level: "high|medium|low|critical"
---
```

### Operations Documents  
```yaml
---
# Base fields + operations extensions
procedure_type: "daily|weekly|monthly|emergency|adhoc"
automation_level: "manual|semi-automated|automated"
estimated_duration: "30 min"
frequency: "daily|weekly|monthly"
criticality: "high|medium|low|critical"
---
```

### Reference Documents
```yaml
---
# Base fields + reference extensions  
technical_domain: "hooks|commands|architecture|ci-cd"
complexity_level: "basic|intermediate|advanced|expert"
implementation_status: "design|prototype|stable|deprecated"
code_examples: true
troubleshooting_guide: true
---
```

## 🔧 Usage & Validation

### Manual Validation
```bash
# 現在の検証方法（python scripts/validate_frontmatter.py は未実装）
# 手動でスキーマ構造を確認:
python -c "import json; print(json.dumps(json.load(open('schemas/md-meta.schema.json')), indent=2))"

# 全ドキュメントの Front-Matter 解析
python scripts/doc_inventory.py --format=json
```

### CI Integration
```bash
# GitHub Actions validation (計画中 - 未実装)
# 将来実装: .github/workflows/docs-ci.yml
```

### Schema Selection Logic
The validation system automatically selects the appropriate schema based on the `category` field:

1. **governance** → `governance.schema.json`
2. **operations** → `operations.schema.json`  
3. **reference** → `reference.schema.json`
4. **templates** → `md-meta.schema.json` (base)
5. **quickstart** → `md-meta.schema.json` (base)

## 📋 Common Field Definitions

### Status Values
- **draft**: Work in progress, not yet reviewed
- **active**: Current and in use
- **deprecated**: Outdated, scheduled for removal
- **proposed**: Awaiting approval (governance)
- **accepted**: Approved and implemented (governance)
- **rejected**: Rejected proposal (governance)
- **superseded**: Replaced by newer document

### Priority Levels
- **high**: Critical for operations/development
- **medium**: Important but not urgent  
- **low**: Nice to have, low priority

### Tag Conventions
- Use lowercase, hyphen-separated format
- Maximum 10 tags per document
- Examples: `["complexity", "governance", "ci-cd", "front-matter"]`

## 🛠️ Schema Development

### Adding New Fields
1. Update the appropriate schema file
2. Add examples and descriptions
3. Update this README with field documentation
4. Test with existing documents
5. Update validation scripts if needed

### Schema Validation Testing
```bash
# Test schema itself for validity
python -c "import json, jsonschema; jsonschema.Draft7Validator.check_schema(json.load(open('schemas/md-meta.schema.json')))"

# Test against example documents (未実装)
# 将来実装: python scripts/validate_frontmatter.py --test-examples
```

## 📈 Integration with Document Complexity Control

These schemas are integral to the Document Complexity Control System (ADR-005):

1. **CI Validation**: Automatic Front-Matter validation in GitHub Actions (計画中)
2. **SQLite Integration**: Structured metadata extraction for analytics (計画中)  
3. **Complexity Monitoring**: Consistent categorization for complexity metrics (部分実装)
4. **Search & Discovery**: Standardized tags and categories for document discovery (計画中)

### 現在の実装状況
- ✅ **スキーマ定義**: 完了 (md-meta.schema.json 他)
- ✅ **文書複雑性分析**: 完了 (scripts/doc_inventory.py)
- ❌ **Front-Matter検証**: 未実装 (scripts/validate_frontmatter.py)
- ❌ **CI統合**: 未実装 (.github/workflows/docs-ci.yml)
- ❌ **SQLite統合**: 未実装

## 🔗 Related Documentation

- **[ADR-005](../governance/adr/005-document-complexity-control-system.md)**: Document Complexity Control System decision
- **[Document Inventory Script](../scripts/doc_inventory.py)**: 文書複雑性分析ツール
- **[Governance README](../governance/README.md)**: ガバナンス手順・ADR管理

---

*Schema definitions follow JSON Schema Draft 7 specification and support the Front-Matter standardization initiative outlined in ADR-005.*

*Last updated: 2025-07-14*