# Cross-Project Search Commands

## Find Function/Class Across Projects
```bash
# Search for function definitions across all projects
rg "def|function|class" --type py --type bas /home/kenic/projects/

# Search for specific function name
rg "function_name" /home/kenic/projects/
```

## Find Configuration Files
```bash
# Find all config files
find /home/kenic/projects/ -name "*.json" -o -name "*.yaml" -o -name "*.yml" -o -name "*.ini"

# Find project-specific configs
find /home/kenic/projects/ -name "config*" -o -name "settings*"
```

## Project Health Check
```bash
# Check for common issues across projects
rg "TODO|FIXME|BUG|HACK" /home/kenic/projects/

# Find files without proper headers
find /home/kenic/projects/ -name "*.py" -exec grep -L "#!/usr/bin/env python" {} \;
```

## Dependency Analysis
```bash
# Python dependencies
find /home/kenic/projects/ -name "requirements*.txt" -o -name "pyproject.toml" -o -name "setup.py"

# Check for outdated imports
rg "from.*import|import.*" --type py /home/kenic/projects/
```