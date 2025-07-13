# Project Analysis Prompt Template

## Context
You are working in a multi-project development workspace containing:
- **danbooru_advanced_wildcard**: ML/data science project for ComfyUI wildcard generation
- **pdi**: VBA automation project for business processes

## Instructions
When analyzing code across projects:

1. **Identify Project Context**
   - Determine which project the code belongs to
   - Understand the project's primary language and framework
   - Consider project-specific conventions and patterns

2. **Cross-Project Considerations**
   - Look for potential code reuse opportunities
   - Identify shared dependencies or utilities
   - Consider impact on other projects when making changes

3. **Documentation Standards**
   - Follow project-specific documentation patterns
   - Update relevant CLAUDE.md files
   - Maintain consistency with existing code style

## Project-Specific Guidelines

### danbooru_advanced_wildcard
- Primary language: Python
- Focus: ML/data analysis, performance optimization
- Key patterns: Parquet data processing, statistical analysis
- Testing: pytest-based comprehensive test suite

### pdi
- Primary language: VBA
- Focus: Business process automation
- Key patterns: Excel operations, data transfer workflows
- Structure: Modular .bas files with integrated refactoring