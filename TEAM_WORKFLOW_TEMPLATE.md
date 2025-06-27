# Team Workflow Template: OpenAPI & Insomnia Management

This template provides standardized commands and workflows for teams to create, update, and manage OpenAPI specifications and their corresponding Insomnia collections.

## 🚀 Quick Start Commands

### Initial Setup (One-time per repository)
```bash
# 1. Make the script executable
chmod +x update-insomnia.sh

# 2. Verify prerequisites
go version                                    # Ensure Go is installed
ls cmd/insomnia-generator/main.go            # Verify generator exists
```

## 📋 Standard Workflow Templates

### Template 1: Creating a New API Specification

#### Step 1: Create OpenAPI Spec File
```bash
# Command template:
# touch {api-name}.yml

# Examples:
touch users-api.yml
touch orders-api.yml
touch inventory-api.yml
```

#### Step 2: Use OpenAPI Template Structure
```yaml
# Copy this template to your new .yml file:
openapi: 3.0.3
info:
  title: {API_NAME} API
  description: API endpoints for managing {RESOURCE_DESCRIPTION}
  version: 1.0.0
  contact:
    name: API Support
    email: support@{your-domain}.com

servers:
  - url: http://localhost:{PORT}/api/v1
    description: Local development server

paths:
  /{resource}:
    get:
      summary: Get all {resources}
      description: Retrieves a list of all {resources}
      operationId: getAll{Resources}
      tags:
        - {resources}
      # Add parameters, responses, etc.

components:
  schemas:
    {Resource}:
      type: object
      description: {Resource} details
      required:
        - id
        # Add other required fields
      properties:
        id:
          type: integer
          format: int64
          description: Unique identifier
          example: 1
        # Add other properties

    ErrorResponse:
      type: object
      description: Standard error response structure
      required:
        - code
        - message
      properties:
        code:
          type: string
          description: Error code identifying the type of error
          enum:
            - INVALID_REQUEST
            - NOT_FOUND
            - CONFLICT
            - INTERNAL_ERROR
          example: "NOT_FOUND"
        message:
          type: string
          description: Human-readable error message
          example: "{Resource} not found"

tags:
  - name: {resources}
    description: Operations related to {resources}
```

#### Step 3: Generate Insomnia File
```bash
# Command template:
# ./update-insomnia.sh -i {api-name}.yml -o {api-name}_insomnia.yaml

# Examples:
./update-insomnia.sh -i users-api.yml -o users-api_insomnia.yaml
./update-insomnia.sh -i orders-api.yml -o orders-api_insomnia.yaml
./update-insomnia.sh -i inventory-api.yml -o inventory-api_insomnia.yaml
```

### Template 2: Updating Existing API Specification

#### Standard Update Process
```bash
# 1. Edit the OpenAPI spec file
vim {api-name}.yml                           # or your preferred editor

# 2. Update the Insomnia file (preserves IDs)
./update-insomnia.sh -i {api-name}.yml -o {api-name}_insomnia.yaml

# 3. Verify the update
ls -la {api-name}_insomnia.yaml*             # Check for backup file
```

#### Force Recreate (when needed)
```bash
# Use when you want completely fresh Insomnia file
./update-insomnia.sh -i {api-name}.yml -o {api-name}_insomnia.yaml --create
```

### Template 3: Batch Processing Multiple APIs

#### Process All APIs in Project
```bash
#!/bin/bash
# Create this as a script: batch-update-insomnia.sh

echo "🔄 Batch updating all Insomnia files..."

# List your API files here
API_FILES=(
    "users-api.yml"
    "orders-api.yml"
    "inventory-api.yml"
    "payments-api.yml"
)

for api in "${API_FILES[@]}"; do
    if [ -f "$api" ]; then
        output_file="${api%.yml}_insomnia.yaml"
        echo "Processing: $api → $output_file"
        ./update-insomnia.sh -i "$api" -o "$output_file"
    else
        echo "⚠️  Warning: $api not found, skipping..."
    fi
done

echo "✅ Batch processing complete!"
```

```bash
# Make it executable and run
chmod +x batch-update-insomnia.sh
./batch-update-insomnia.sh
```

## 🎯 Common API Endpoint Templates

### REST API Standard Endpoints
```yaml
# Copy these path templates for standard CRUD operations:

paths:
  /{resource}:
    get:
      summary: Get all {resources}
      # ... implementation
    post:
      summary: Create {resource}
      # ... implementation

  /{resource}/{id}:
    get:
      summary: Get {resource} by ID
      # ... implementation
    put:
      summary: Update {resource}
      # ... implementation
    delete:
      summary: Delete {resource}
      # ... implementation

  /{resource}/{id}/{sub-resource}:
    get:
      summary: Get {sub-resources} for {resource}
      # ... implementation
```

### Common HTTP Response Templates
```yaml
responses:
  '200':
    description: Successfully retrieved {resource}
    content:
      application/json:
        schema:
          $ref: '#/components/schemas/{Resource}'
  '201':
    description: {Resource} successfully created
    content:
      application/json:
        schema:
          $ref: '#/components/schemas/{Resource}'
  '400':
    description: Invalid request data
    content:
      application/json:
        schema:
          $ref: '#/components/schemas/ErrorResponse'
  '404':
    description: {Resource} not found
    content:
      application/json:
        schema:
          $ref: '#/components/schemas/ErrorResponse'
  '500':
    description: Internal server error
    content:
      application/json:
        schema:
          $ref: '#/components/schemas/ErrorResponse'
```

## 📂 File Naming Conventions

### Recommended Naming Pattern
```
# OpenAPI Files:
{service-name}-api.yml          # users-api.yml, orders-api.yml
{version}-{service-name}.yml    # v1-users.yml, v2-orders.yml

# Insomnia Files:
{service-name}-api_insomnia.yaml      # users-api_insomnia.yaml
{version}-{service-name}_insomnia.yaml # v1-users_insomnia.yaml
```

### Directory Structure
```
project-root/
├── api-specs/
│   ├── users-api.yml
│   ├── orders-api.yml
│   └── inventory-api.yml
├── insomnia-collections/
│   ├── users-api_insomnia.yaml
│   ├── orders-api_insomnia.yaml
│   └── inventory-api_insomnia.yaml
└── scripts/
    ├── update-insomnia.sh
    └── batch-update-insomnia.sh
```

## 🔧 Development Workflow Commands

### Daily Development Cycle
```bash
# 1. Start working on API changes
git checkout -b feature/update-users-api

# 2. Edit OpenAPI spec
vim users-api.yml

# 3. Update Insomnia collection
./update-insomnia.sh -i users-api.yml -o users-api_insomnia.yaml

# 4. Test in Insomnia (import the updated collection)

# 5. Commit changes
git add users-api.yml users-api_insomnia.yaml
git commit -m "feat: add user profile endpoints to users API"

# 6. Push and create PR
git push origin feature/update-users-api
```

### Pre-commit Validation
```bash
# Create this as: validate-apis.sh
#!/bin/bash

echo "🔍 Validating OpenAPI specifications..."

# Find all OpenAPI files
for file in *-api.yml *.openapi.yml api-specs/*.yml; do
    if [ -f "$file" ]; then
        echo "Validating: $file"
        
        # Basic YAML syntax check
        python -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "✅ $file: Valid YAML"
        else
            echo "❌ $file: Invalid YAML syntax"
            exit 1
        fi
        
        # Check for required OpenAPI fields
        if grep -q "openapi:" "$file" && grep -q "info:" "$file" && grep -q "paths:" "$file"; then
            echo "✅ $file: Valid OpenAPI structure"
        else
            echo "❌ $file: Missing required OpenAPI fields"
            exit 1
        fi
    fi
done

echo "🎉 All API specifications are valid!"
```

## 🚨 Troubleshooting Commands

### Common Issue Resolution
```bash
# Issue: Script permission denied
chmod +x update-insomnia.sh

# Issue: Go module problems
go mod tidy
go mod download

# Issue: Check if generator exists
ls -la cmd/insomnia-generator/main.go

# Issue: Validate YAML syntax
python -c "import yaml; print(yaml.safe_load(open('your-api.yml')))"

# Issue: Check backup files
ls -la *_insomnia.yaml.backup

# Issue: Clean up temporary files
rm -f temp-insomnia-*.yml
```

### Debug Information
```bash
# Get help
./update-insomnia.sh --help

# Test with verbose output (if your generator supports it)
go run cmd/insomnia-generator/main.go -input api.yml -output test.yml -verbose

# Check file permissions
ls -la *.yml *.yaml
```

## 📊 Quality Assurance Checklist

### Before Committing Changes
- [ ] OpenAPI file passes YAML validation
- [ ] All required OpenAPI 3.0.3 fields are present
- [ ] Insomnia file generates without errors
- [ ] Backup files are created (for updates)
- [ ] File naming follows team conventions
- [ ] API endpoints follow REST conventions
- [ ] Error responses use standard ErrorResponse schema
- [ ] Examples are provided for all endpoints
- [ ] Tags are properly assigned

### Before Pushing to Repository
```bash
# Run these commands:
./validate-apis.sh                    # Validate all API specs
./batch-update-insomnia.sh           # Ensure all Insomnia files are current
git status                           # Check what files are changed
git diff --name-only                 # Review changed files
```

## 🔄 CI/CD Integration Template

### GitHub Actions Workflow
```yaml
# .github/workflows/api-validation.yml
name: API Validation

on:
  pull_request:
    paths:
      - '**/*.yml'
      - '**/*.yaml'

jobs:
  validate-apis:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Go
        uses: actions/setup-go@v3
        with:
          go-version: '1.19'
      
      - name: Install dependencies
        run: go mod download
      
      - name: Validate OpenAPI specs
        run: ./validate-apis.sh
      
      - name: Update Insomnia collections
        run: ./batch-update-insomnia.sh
      
      - name: Check for changes
        run: |
          if [ -n "$(git status --porcelain)" ]; then
            echo "Error: Insomnia files are out of sync with OpenAPI specs"
            git diff
            exit 1
          fi
```

## 📞 Team Support

### Getting Help
1. **Check this guide first** - Most common scenarios are covered
2. **Use the help command**: `./update-insomnia.sh --help`  
3. **Check error messages** - They provide specific guidance
4. **Verify file paths** - Ensure all files exist and paths are correct
5. **Ask the team** - Share knowledge about common issues

### Reporting Issues
When reporting problems, include:
```bash
# System information
go version
pwd
ls -la *.yml *.yaml

# Error output
./update-insomnia.sh -i your-api.yml -o your-api_insomnia.yaml 2>&1

# File validation
head -20 your-api.yml
```

---

*This template is designed to standardize OpenAPI and Insomnia file management across all team projects. Adapt the commands and file names to match your specific project needs.* 