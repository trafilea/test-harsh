#!/bin/bash

# Smart Insomnia File Generator/Updater Script
# This script creates new or updates existing Insomnia files from OpenAPI specs

set -e

# Configuration - you can modify these for different projects
OPENAPI_FILE="address.yml"
INSOMNIA_FILE=""  # Will be auto-generated if not specified
TEMP_FILE="temp-insomnia-update.yml"

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -i, --input FILE     OpenAPI spec file (default: address.yml)"
    echo "  -o, --output FILE    Insomnia output file (auto-generated if not specified)"
    echo "  -f, --force          Force overwrite existing file without backup"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Use defaults"
    echo "  $0 -i api.yml                        # Specify input file"
    echo "  $0 -i api.yml -o my-insomnia.yml     # Specify both files"
    echo "  $0 --force                           # Skip backup creation"
}

# Parse command line arguments
FORCE_OVERWRITE=false
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--input)
            OPENAPI_FILE="$2"
            shift 2
            ;;
        -o|--output)
            INSOMNIA_FILE="$2"
            shift 2
            ;;
        -f|--force)
            FORCE_OVERWRITE=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "❌ Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Auto-generate Insomnia filename if not specified
if [ -z "$INSOMNIA_FILE" ]; then
    # Try to find existing Insomnia file in current directory
    EXISTING_FILES=()
    while IFS= read -r -d '' file; do
        EXISTING_FILES+=("$file")
    done < <(find . -maxdepth 1 \( -name "*wrk_*.yaml" -o -name "*wrk_*.yml" \) -print0 2>/dev/null)
    
    if [ ${#EXISTING_FILES[@]} -eq 1 ]; then
        INSOMNIA_FILE="${EXISTING_FILES[0]}"
        echo "🔍 Found existing Insomnia file: $INSOMNIA_FILE"
    elif [ ${#EXISTING_FILES[@]} -gt 1 ]; then
        echo "⚠️  Multiple Insomnia files found:"
        for file in "${EXISTING_FILES[@]}"; do
            echo "   - $file"
        done
        echo "Please specify which one to update with -o option"
        exit 1
    else
        # Generate new filename based on OpenAPI spec
        if [ -f "$OPENAPI_FILE" ]; then
            API_TITLE=$(grep -m1 "title:" "$OPENAPI_FILE" | sed 's/.*title: *//' | tr -d '"' | sed 's/ /_/g')
            API_VERSION=$(grep -m1 "version:" "$OPENAPI_FILE" | sed 's/.*version: *//' | tr -d '"')
            INSOMNIA_FILE="${API_TITLE}_${API_VERSION}-insomnia.yaml"
            echo "📝 Will create new Insomnia file: $INSOMNIA_FILE"
        else
            INSOMNIA_FILE="api-insomnia.yaml" 
            echo "📝 Will create new Insomnia file: $INSOMNIA_FILE"
        fi
    fi
fi

BACKUP_FILE="${INSOMNIA_FILE}.backup"

echo "🔄 Processing Insomnia file from OpenAPI spec..."
echo "📄 Input:  $OPENAPI_FILE"
echo "📄 Output: $INSOMNIA_FILE"

# Check if OpenAPI file exists
if [ ! -f "$OPENAPI_FILE" ]; then
    echo "❌ Error: OpenAPI file '$OPENAPI_FILE' not found"
    exit 1
fi

# Determine operation mode
if [ -f "$INSOMNIA_FILE" ]; then
    echo "📂 Existing Insomnia file found - UPDATE MODE"
    UPDATE_MODE=true
    
    # Create backup of original file
    if [ "$FORCE_OVERWRITE" != true ]; then
        echo "📦 Creating backup: $BACKUP_FILE"
        cp "$INSOMNIA_FILE" "$BACKUP_FILE"
    else
        echo "⚠️  Skipping backup (--force flag used)"
    fi
    
    # Extract original metadata
    echo "🔍 Extracting original metadata..."
    ORIGINAL_ID=$(grep "id: wrk_" "$INSOMNIA_FILE" | head -1 | sed 's/.*id: //' | tr -d ' ')
    ORIGINAL_CREATED=$(grep "created:" "$INSOMNIA_FILE" | head -1 | sed 's/.*created: //' | tr -d ' ')
    FOLDER_ID=$(grep "id: fld_" "$INSOMNIA_FILE" | head -1 | sed 's/.*id: //' | tr -d ' ')
    COOKIE_JAR_ID=$(grep "id: jar_" "$INSOMNIA_FILE" | head -1 | sed 's/.*id: //' | tr -d ' ')
    ENV_ID=$(grep "id: env_" "$INSOMNIA_FILE" | head -1 | sed 's/.*id: //' | tr -d ' ')
    SPEC_ID=$(grep "id: spc_" "$INSOMNIA_FILE" | head -1 | sed 's/.*id: //' | tr -d ' ')
    
    echo "📝 Original IDs to preserve:"
    echo "   Workspace: $ORIGINAL_ID"
    echo "   Folder: $FOLDER_ID" 
    echo "   Cookie Jar: $COOKIE_JAR_ID"
    echo "   Environment: $ENV_ID"
    echo "   Spec: $SPEC_ID"
else
    echo "🆕 No existing Insomnia file found - CREATE MODE"
    UPDATE_MODE=false
    
    # Check if file would be overwritten
    if [ -f "$INSOMNIA_FILE" ] && [ "$FORCE_OVERWRITE" != true ]; then
        echo "❌ File '$INSOMNIA_FILE' would be overwritten. Use --force to continue."
        exit 1
    fi
fi

# Generate new file with our generator
if [ "$UPDATE_MODE" = true ]; then
    echo "⚙️  Generating updated Insomnia file..."
else
    echo "⚙️  Generating new Insomnia file..."
fi

go run cmd/insomnia-generator/main.go -input "$OPENAPI_FILE" -output "$TEMP_FILE"

if [ ! -f "$TEMP_FILE" ]; then
    echo "❌ Error: Failed to generate file"
    exit 1
fi

# If updating existing file, preserve original IDs
if [ "$UPDATE_MODE" = true ]; then
    echo "🔧 Restoring original IDs..."
    
    # Get new IDs from generated file
    NEW_WORKSPACE_ID=$(grep "id: wrk_" "$TEMP_FILE" | head -1 | sed 's/.*id: //' | tr -d ' ')
    NEW_FOLDER_ID=$(grep "id: fld_" "$TEMP_FILE" | head -1 | sed 's/.*id: //' | tr -d ' ')
    NEW_COOKIE_JAR_ID=$(grep "id: jar_" "$TEMP_FILE" | head -1 | sed 's/.*id: //' | tr -d ' ')
    NEW_ENV_ID=$(grep "id: env_" "$TEMP_FILE" | head -1 | sed 's/.*id: //' | tr -d ' ')
    NEW_SPEC_ID=$(grep "id: spc_" "$TEMP_FILE" | head -1 | sed 's/.*id: //' | tr -d ' ')
    
    # Replace IDs in temp file
    sed -i.bak "s/$NEW_WORKSPACE_ID/$ORIGINAL_ID/g" "$TEMP_FILE"
    sed -i.bak "s/$NEW_FOLDER_ID/$FOLDER_ID/g" "$TEMP_FILE"
    sed -i.bak "s/$NEW_COOKIE_JAR_ID/$COOKIE_JAR_ID/g" "$TEMP_FILE"
    sed -i.bak "s/$NEW_ENV_ID/$ENV_ID/g" "$TEMP_FILE"
    sed -i.bak "s/$NEW_SPEC_ID/$SPEC_ID/g" "$TEMP_FILE"
    
    # Also preserve the original creation timestamp
    NEW_CREATED=$(grep "created:" "$TEMP_FILE" | head -1 | sed 's/.*created: //' | tr -d ' ')
    sed -i.bak "s/created: $NEW_CREATED/created: $ORIGINAL_CREATED/" "$TEMP_FILE"
    
    # Clean up sed backup files
    rm -f "$TEMP_FILE.bak"
fi

# Move the generated file to final location
if [ "$UPDATE_MODE" = true ]; then
    echo "📝 Updating existing file..."
else
    echo "📝 Creating new file..."
fi

mv "$TEMP_FILE" "$INSOMNIA_FILE"

# Print success message
if [ "$UPDATE_MODE" = true ]; then
    echo "✅ Successfully updated $INSOMNIA_FILE"
    echo "📋 Summary:"
    echo "   - Preserved original workspace ID: $ORIGINAL_ID"
    echo "   - Updated API endpoints from $OPENAPI_FILE"
    if [ "$FORCE_OVERWRITE" != true ]; then
        echo "   - Backup saved as: $BACKUP_FILE"
    fi
else
    echo "✅ Successfully created $INSOMNIA_FILE"
    echo "📋 Summary:"
    echo "   - Generated new Insomnia workspace from $OPENAPI_FILE"
    echo "   - Ready to import into Insomnia REST Client"
fi

echo ""
echo "🎉 Insomnia file is ready to use!"

# Show next steps for new files
if [ "$UPDATE_MODE" = false ]; then
    echo ""
    echo "📚 Next steps:"
    echo "   1. Open Insomnia REST Client"
    echo "   2. Go to Application > Preferences > Data > Import Data"
    echo "   3. Select '$INSOMNIA_FILE'"
    echo "   4. Your API workspace will be imported with all endpoints"
fi 