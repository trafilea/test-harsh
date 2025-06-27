#!/bin/bash

# OpenAPI Validation Script
# This script validates OpenAPI specification files for common issues

set -e

echo "🔍 Validating OpenAPI specifications..."

# Find all potential OpenAPI files
API_FILES=($(find . -name "*.yml" -o -name "*.yaml" | grep -E "(api|openapi)" | grep -v "_insomnia" | sort))

# If no API files found, check for common patterns but exclude common non-API files
if [ ${#API_FILES[@]} -eq 0 ]; then
    echo "🔍 No API files found with standard patterns, checking all YAML files..."
    API_FILES=($(find . -name "*.yml" -o -name "*.yaml" | grep -v "_insomnia" | grep -v ".backup" | grep -v ".github" | grep -v "docker-compose" | grep -v "config" | sort))
fi

if [ ${#API_FILES[@]} -eq 0 ]; then
    echo "❌ No YAML files found to validate"
    exit 1
fi

echo "📋 Found ${#API_FILES[@]} files to validate:"
printf "   %s\n" "${API_FILES[@]}"
echo ""

# Counters
VALID=0
INVALID=0

# Validate each file
for file in "${API_FILES[@]}"; do
    echo "🔍 Validating: $file"
    
    # Check if file exists and is readable
    if [ ! -f "$file" ] || [ ! -r "$file" ]; then
        echo "❌ $file: File not found or not readable"
        ((INVALID++))
        continue
    fi
    
    # Basic YAML syntax check
    echo "   Checking YAML syntax..."
    if command -v python3 &> /dev/null; then
        python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null
    elif command -v python &> /dev/null; then
        python -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null
    else
        echo "   ⚠️  Python not found, skipping YAML syntax check"
    fi
    
    if [ $? -eq 0 ]; then
        echo "   ✅ Valid YAML syntax"
    else
        echo "   ❌ Invalid YAML syntax"
        ((INVALID++))
        continue
    fi
    
    # Check for required OpenAPI fields
    echo "   Checking OpenAPI structure..."
    REQUIRED_FIELDS=("openapi:" "info:" "paths:")
    MISSING_FIELDS=()
    
    for field in "${REQUIRED_FIELDS[@]}"; do
        if ! grep -q "^$field" "$file"; then
            MISSING_FIELDS+=("$field")
        fi
    done
    
    if [ ${#MISSING_FIELDS[@]} -eq 0 ]; then
        echo "   ✅ Valid OpenAPI structure"
    else
        echo "   ❌ Missing required fields: ${MISSING_FIELDS[*]}"
        ((INVALID++))
        continue
    fi
    
    # Check OpenAPI version
    echo "   Checking OpenAPI version..."
    OPENAPI_VERSION=$(grep "^openapi:" "$file" | sed 's/openapi: *//g' | tr -d '"' | tr -d "'")
    if [[ "$OPENAPI_VERSION" =~ ^3\.[0-9]+\.[0-9]+$ ]]; then
        echo "   ✅ Valid OpenAPI version: $OPENAPI_VERSION"
    else
        echo "   ⚠️  Unusual OpenAPI version: $OPENAPI_VERSION (expected 3.x.x)"
    fi
    
    # Check for common best practices
    echo "   Checking best practices..."
    
    # Check for info.title
    if grep -q "title:" "$file"; then
        echo "   ✅ Has title"
    else
        echo "   ⚠️  Missing title in info section"
    fi
    
    # Check for info.version
    if grep -q "version:" "$file"; then
        echo "   ✅ Has version"
    else
        echo "   ⚠️  Missing version in info section"
    fi
    
    # Check for servers
    if grep -q "servers:" "$file"; then
        echo "   ✅ Has servers configuration"
    else
        echo "   ⚠️  Missing servers configuration"
    fi
    
    # Check for components/schemas
    if grep -q "components:" "$file" && grep -q "schemas:" "$file"; then
        echo "   ✅ Has component schemas"
    else
        echo "   ⚠️  Missing component schemas"
    fi
    
    # Check for tags
    if grep -q "tags:" "$file"; then
        echo "   ✅ Uses tags"
    else
        echo "   ⚠️  No tags found"
    fi
    
    echo "   ✅ $file: Validation complete"
    ((VALID++))
    echo ""
done

# Final report
echo "📊 Validation Summary:"
echo "   ✅ Valid files: $VALID"
echo "   ❌ Invalid files: $INVALID"
echo "   📁 Total files: ${#API_FILES[@]}"

if [ $INVALID -gt 0 ]; then
    echo ""
    echo "🚨 Some files failed validation. Please fix the errors above before proceeding."
    exit 1
else
    echo ""
    echo "🎉 All API specifications are valid!"
fi 