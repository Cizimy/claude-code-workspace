# Workspace Maintenance Commands

## Test All Projects
```bash
# Run tests for Python projects
cd /home/kenic/projects/danbooru_advanced_wildcard && python -m pytest
cd /home/kenic/projects/pdi && python -m pytest 2>/dev/null || echo "No Python tests in PDI"

# Comprehensive test run
find /home/kenic/projects/ -name "test_*.py" -o -name "*_test.py" | head -5
```

## Lint All Projects
```bash
# Python linting
find /home/kenic/projects/ -name "*.py" -exec ruff check {} \;

# Format Python code
find /home/kenic/projects/ -name "*.py" -exec ruff format {} \;
```

## Git Operations
```bash
# Status across all Git repositories
find /home/kenic/projects/ -name ".git" -type d | while read gitdir; do
  cd "$(dirname "$gitdir")"
  echo "=== $(pwd) ==="
  git status --porcelain
done

# Commit all changes
find /home/kenic/projects/ -name ".git" -type d | while read gitdir; do
  cd "$(dirname "$gitdir")"
  if [ -n "$(git status --porcelain)" ]; then
    echo "=== Committing changes in $(pwd) ==="
    git add .
    git commit -m "Workspace maintenance commit"
  fi
done
```

## Cleanup Operations
```bash
# Remove Python cache files
find /home/kenic/projects/ -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null
find /home/kenic/projects/ -name "*.pyc" -delete

# Remove temporary files
find /home/kenic/projects/ -name "*.tmp" -o -name "*.temp" -delete
```