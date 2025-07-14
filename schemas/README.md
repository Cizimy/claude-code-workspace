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
# Validate single document
python scripts/validate_frontmatter.py document.md

# Validate all documents
python scripts/validate_frontmatter.py
```

### CI Integration
```bash
# GitHub Actions validation (automatic)
# See .github/workflows/docs-ci.yml
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

# Test against example documents
python scripts/validate_frontmatter.py --test-examples
```

## 📈 Integration with Document Complexity Control

These schemas are integral to the Document Complexity Control System (ADR-005):

1. **CI Validation**: Automatic Front-Matter validation in GitHub Actions
2. **SQLite Integration**: Structured metadata extraction for analytics
3. **Complexity Monitoring**: Consistent categorization for complexity metrics
4. **Search & Discovery**: Standardized tags and categories for document discovery

## 🔗 Related Documentation

- **[ADR-005](../governance/adr/005-document-complexity-control-system.md)**: Document Complexity Control System decision
- **[Document Complexity Monitoring](../.claude/docs/03_operations/document_complexity_monitoring.md)**: Daily operations guide
- **[Technical Specification](../.claude/docs/04_reference/document-complexity-control-system.md)**: Implementation details

---

*Schema definitions follow JSON Schema Draft 7 specification and support the Front-Matter standardization initiative outlined in ADR-005.*

*Last updated: 2025-07-14*