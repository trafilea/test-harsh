# 🚀 Insomnia Generator System - Complete Guide

This guide covers the enhanced Insomnia generator system that can both **create new** and **update existing** Insomnia workspace files from OpenAPI specifications.

## 🎯 Overview

The system now intelligently handles two scenarios:
- **CREATE MODE**: Generate new Insomnia files for new services
- **UPDATE MODE**: Update existing Insomnia files while preserving workspace IDs

## 🛠️ Tools Available

### 1. **Smart Update Script** (`update-insomnia.sh`)
Enhanced script that automatically detects whether to create or update.

### 2. **CLI Generator** (`cmd/insomnia-generator/`)
Direct conversion tool for one-time generation.

### 3. **File Watcher** (`cmd/insomnia-watcher/`)
Continuous monitoring for real-time updates.

### 4. **Go Package** (`pkg/insomnia/`)
Programmatic API for integration into other tools.

## 📋 Usage Scenarios

### 🆕 **New Service (CREATE MODE)**

When starting a new service with no existing Insomnia file:

```bash
# Auto-detect mode (recommended)
./update-insomnia.sh -i my-new-api.yml

# Specify output file
./update-insomnia.sh -i my-new-api.yml -o MyService-insomnia.yaml

# Using the direct generator
go run cmd/insomnia-generator/main.go -input my-new-api.yml
```

**What happens:**
- ✅ Creates new Insomnia workspace with fresh IDs
- ✅ Generates filename based on API title and version
- ✅ Provides import instructions for Insomnia
- ✅ No backup needed (new file)

### 🔄 **Existing Service (UPDATE MODE)**

When updating an existing service with an Insomnia file:

```bash
# Auto-detect existing file
./update-insomnia.sh -i address.yml

# Specify exact files
./update-insomnia.sh -i address.yml -o "Address API 1.0.0-wrk_*.yaml"

# Skip backup creation
./update-insomnia.sh -i address.yml --force
```

**What happens:**
- ✅ Detects existing Insomnia file automatically
- ✅ Preserves original workspace ID and structure
- ✅ Creates backup before updating
- ✅ Updates content while maintaining continuity

## 🔧 Script Options

```bash
./update-insomnia.sh [OPTIONS]

Options:
  -i, --input FILE     OpenAPI spec file (default: address.yml)
  -o, --output FILE    Insomnia output file (auto-generated if not specified)
  -f, --force          Force overwrite existing file without backup
  -h, --help           Show this help message
```

## 🎬 Workflow Examples

### Scenario 1: Brand New Microservice

```bash
# 1. Create your OpenAPI spec
vim user-service.yml

# 2. Generate Insomnia workspace
./update-insomnia.sh -i user-service.yml

# 3. Import into Insomnia
# File: User_Service_1.0.0-insomnia.yaml created
# Follow the displayed import instructions
```

### Scenario 2: Existing Service Evolution

```bash
# 1. Modify your existing OpenAPI spec
vim address.yml  # Add new endpoints

# 2. Update Insomnia workspace (preserves IDs)
./update-insomnia.sh -i address.yml

# 3. Insomnia automatically picks up changes
# No re-import needed - same workspace ID preserved
```

### Scenario 3: Multiple APIs in Project

```bash
# If multiple Insomnia files exist, specify which one
./update-insomnia.sh -i orders-api.yml -o "Orders API-wrk_*.yaml"

# Or let the script help you choose
./update-insomnia.sh -i orders-api.yml
# Script will list found files and ask you to specify
```

## 🧠 Smart Detection Logic

The script uses intelligent detection:

1. **Auto-find Existing Files**: Scans for `*wrk_*.yaml` files
2. **Single File Found**: Automatically updates it
3. **Multiple Files Found**: Asks you to specify which one
4. **No Files Found**: Creates new file with auto-generated name
5. **Manual Override**: Use `-o` to specify exact file

## 🔄 File Watcher for Development

For active development, use the continuous watcher:

```bash
# Watch specific file
go run cmd/insomnia-watcher/main.go -file address.yml

# Watch entire directory
go run cmd/insomnia-watcher/main.go -dir ./api-specs

# Custom polling interval
go run cmd/insomnia-watcher/main.go -file address.yml -interval 5
```

## 📁 File Organization Best Practices

### Recommended Structure
```
project/
├── api/
│   ├── address.yml           # OpenAPI specs
│   ├── user.yml
│   └── order.yml
├── insomnia/
│   ├── Address_API_1.0.0-wrk_*.yaml   # Insomnia workspaces
│   ├── User_API_1.0.0-wrk_*.yaml
│   └── Order_API_1.0.0-wrk_*.yaml
└── scripts/
    └── update-insomnia.sh    # Update script
```

### Naming Conventions
- **OpenAPI**: `service-name.yml`
- **Insomnia**: `ServiceName_Version-insomnia.yaml` (auto-generated)
- **Insomnia (existing)**: `Original Filename-wrk_*.yaml` (preserved)

## 🔒 ID Preservation Logic

When updating existing files, the system preserves:
- ✅ **Workspace ID** (`wrk_*`) - Most important for Insomnia recognition
- ✅ **Folder IDs** (`fld_*`) - Maintains collection structure
- ✅ **Environment IDs** (`env_*`) - Preserves server configurations
- ✅ **Cookie Jar ID** (`jar_*`) - Keeps cookie settings
- ✅ **Spec ID** (`spc_*`) - Maintains spec metadata
- ✅ **Creation Timestamps** - Original creation time preserved

**New requests get fresh IDs** - Only structural elements are preserved.

## 🚨 Error Handling

The script handles common scenarios:

### File Not Found
```bash
❌ Error: OpenAPI file 'missing.yml' not found
```

### Multiple Files Ambiguity
```bash
⚠️  Multiple Insomnia files found:
   - ./Address API 1.0.0-wrk_*.yaml
   - ./User API 1.0.0-wrk_*.yaml
Please specify which one to update with -o option
```

### Permission Issues
```bash
❌ Error: Cannot write to file (check permissions)
```

## 🎯 Integration with Development Workflow

### CI/CD Pipeline Integration
```yaml
# .github/workflows/api-docs.yml
- name: Update Insomnia Workspaces
  run: |
    for api_file in api/*.yml; do
      ./update-insomnia.sh -i "$api_file"
    done
    
- name: Commit Updated Workspaces
  run: |
    git add insomnia/
    git commit -m "Update Insomnia workspaces" || exit 0
```

### Pre-commit Hook
```bash
#!/bin/bash
# .git/hooks/pre-commit
if git diff --cached --name-only | grep -q "\.yml$"; then
    echo "🔄 Updating Insomnia files..."
    ./update-insomnia.sh
    git add *.yaml
fi
```

## 📊 Summary of Capabilities

| Feature | CREATE Mode | UPDATE Mode |
|---------|-------------|-------------|
| Generate from OpenAPI | ✅ | ✅ |
| Auto-detect files | ✅ | ✅ |
| Preserve workspace IDs | N/A | ✅ |
| Create backups | N/A | ✅ |
| Auto-name files | ✅ | N/A |
| Import instructions | ✅ | N/A |
| Overwrite protection | ✅ | ✅ |

## 🎉 Result

You now have a complete system that handles the entire Insomnia workspace lifecycle:
- 🆕 **Create** new workspaces for new services  
- 🔄 **Update** existing workspaces seamlessly
- 👁️ **Watch** for changes automatically
- 🔧 **Integrate** into development workflows

**No more manual Insomnia file management!** 🚀 