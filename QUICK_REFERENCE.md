# Quick Reference: OpenAPI & Insomnia Commands

## 🚀 Essential Commands

### Create New API Specification
```bash
# Interactive creation with template
./create-new-api.sh -n users -p 8082 -d "User management API"
./create-new-api.sh --name orders --port 8083
```

### Update Existing Insomnia Files
```bash
# Update single file (preserves IDs)
./update-insomnia.sh -i users.yml -o users_insomnia.yaml

# Force recreate (new IDs)
./update-insomnia.sh -i users.yml -o users_insomnia.yaml --create
```

### Batch Processing
```bash
# Update all API files at once
./batch-update-insomnia.sh

# Validate all OpenAPI specs
./validate-apis.sh
```

## 📋 Common Workflows

### Daily Development
```bash
# 1. Create feature branch
git checkout -b feature/update-api

# 2. Edit OpenAPI spec  
vim your-api.yml

# 3. Update Insomnia collection
./update-insomnia.sh -i your-api.yml -o your-api_insomnia.yaml

# 4. Commit changes
git add . && git commit -m "feat: update API endpoints"
```

### Before Pushing Code
```bash
# Validate all specs
./validate-apis.sh

# Ensure all Insomnia files are current
./batch-update-insomnia.sh

# Check git status
git status
```

## 🛠️ Script Options

| Script | Purpose | Key Options |
|--------|---------|-------------|
| `create-new-api.sh` | Create new API from template | `-n name -p port -d description` |
| `update-insomnia.sh` | Update Insomnia collection | `-i input -o output --create` |
| `batch-update-insomnia.sh` | Process multiple APIs | No options (edit script to configure) |
| `validate-apis.sh` | Validate OpenAPI specs | No options (auto-discovers files) |

## 🔧 Quick Fixes

### Common Issues
```bash
# Script permission denied
chmod +x *.sh

# Go module issues
go mod tidy

# YAML syntax error
python -c "import yaml; yaml.safe_load(open('your-api.yml'))"

# Clean temporary files
rm -f temp-insomnia-*.yml
```

### Get Help
```bash
./update-insomnia.sh --help
./create-new-api.sh --help
```

## 📂 File Naming Convention

| File Type | Pattern | Example |
|-----------|---------|---------|
| OpenAPI | `{name}-api.yml` | `users-api.yml` |
| Insomnia | `{name}-api_insomnia.yaml` | `users-api_insomnia.yaml` |
| Backup | `{original}.backup` | `users-api_insomnia.yaml.backup` |

## ⚡ One-Liners

```bash
# Create, validate, and process new API
./create-new-api.sh -n products -p 8084 && ./validate-apis.sh

# Update all and check git status
./batch-update-insomnia.sh && git status

# Quick validation of specific file
python -c "import yaml; print('✅ Valid YAML' if yaml.safe_load(open('api.yml')) else '❌ Invalid')"
```

---

📚 **Full Documentation**: See `TEAM_WORKFLOW_TEMPLATE.md` and `INSOMNIA_SCRIPT_GUIDE.md` 