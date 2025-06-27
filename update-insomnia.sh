#!/bin/bash

# Update/Create Insomnia File Script
# This script generates or updates an Insomnia file from an OpenAPI spec
# while preserving original IDs and structure when updating

set -e

# Default values
OPENAPI_FILE=""
INSOMNIA_FILE=""
CREATE_MODE=false
HELP=false

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Create or update Insomnia collection files from OpenAPI specifications"
    echo ""
    echo "OPTIONS:"
    echo "  -i, --input FILE       OpenAPI specification file (required)"
    echo "  -o, --output FILE      Insomnia output file (required)"
    echo "  -c, --create           Force create mode (overwrite existing file)"
    echo "  -h, --help             Show this help message"
    echo ""
    echo "EXAMPLES:"
    echo "  # Update existing insomnia file"
    echo "  $0 -i address.yml -o address_insomnia.yaml"
    echo ""
    echo "  # Create new insomnia file"
    echo "  $0 -i users.yml -o users_insomnia.yaml"
    echo ""
    echo "  # Force create (overwrite existing)"
    echo "  $0 -i api.yml -o api_insomnia.yaml --create"
    echo ""
    echo "NOTES:"
    echo "  - If output file exists, script will update it preserving IDs"
    echo "  - If output file doesn't exist, script will create a new one"
    echo "  - Use --create flag to force overwrite existing files"
    echo "  - Requires Go insomnia-generator tool in cmd/insomnia-generator/"
}

# Parse command line arguments
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
        -c|--create)
            CREATE_MODE=true
            shift
            ;;
        -h|--help)
            HELP=true
            shift
            ;;
        *)
            echo "❌ Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Show help if requested
if [ "$HELP" = true ]; then
    show_usage
    exit 0
fi

# Validate required arguments
if [ -z "$OPENAPI_FILE" ] || [ -z "$INSOMNIA_FILE" ]; then
    echo "❌ Error: Both input and output files are required"
    echo ""
    show_usage
    exit 1
fi

# Check if OpenAPI file exists
if [ ! -f "$OPENAPI_FILE" ]; then
    echo "❌ Error: OpenAPI file '$OPENAPI_FILE' not found"
    exit 1
fi

# Check if insomnia generator exists
if [ ! -f "cmd/insomnia-generator/main.go" ]; then
    echo "❌ Error: Insomnia generator not found at 'cmd/insomnia-generator/main.go'"
    echo "   Make sure you're running this script from the project root"
    exit 1
fi

# Determine operation mode
UPDATE_MODE=false
if [ -f "$INSOMNIA_FILE" ] && [ "$CREATE_MODE" = false ]; then
    UPDATE_MODE=true
    echo "🔄 Updating existing Insomnia file: $INSOMNIA_FILE"
else
    if [ -f "$INSOMNIA_FILE" ] && [ "$CREATE_MODE" = true ]; then
        echo "🆕 Creating new Insomnia file (overwriting existing): $INSOMNIA_FILE"
    else
        echo "🆕 Creating new Insomnia file: $INSOMNIA_FILE"
    fi
fi

TEMP_FILE="temp-insomnia-$(date +%s).yml"
BACKUP_FILE="${INSOMNIA_FILE}.backup"

# Extract original metadata if updating
if [ "$UPDATE_MODE" = true ]; then
    echo "📦 Creating backup: $BACKUP_FILE"
    cp "$INSOMNIA_FILE" "$BACKUP_FILE"
    
    echo "🔍 Extracting original metadata..."
    ORIGINAL_ID=$(grep "id: wrk_" "$INSOMNIA_FILE" | head -1 | sed 's/.*id: //' | tr -d ' ')
    ORIGINAL_CREATED=$(grep "created:" "$INSOMNIA_FILE" | head -1 | sed 's/.*created: //' | tr -d ' ')
    FOLDER_ID=$(grep "id: fld_" "$INSOMNIA_FILE" | head -1 | sed 's/.*id: //' | tr -d ' ')
    COOKIE_JAR_ID=$(grep "id: jar_" "$INSOMNIA_FILE" | head -1 | sed 's/.*id: //' | tr -d ' ')
    ENV_ID=$(grep "id: env_" "$INSOMNIA_FILE" | head -1 | sed 's/.*id: //' | tr -d ' ')
    
    # Handle spec ID (may not exist in all files)
    SPEC_ID=$(grep "id: spc_" "$INSOMNIA_FILE" | head -1 | sed 's/.*id: //' | tr -d ' ' || echo "")
    
    echo "📝 Original IDs:"
    echo "   Workspace: $ORIGINAL_ID"
    echo "   Folder: $FOLDER_ID" 
    echo "   Cookie Jar: $COOKIE_JAR_ID"
    echo "   Environment: $ENV_ID"
    if [ -n "$SPEC_ID" ]; then
        echo "   Spec: $SPEC_ID"
    fi
fi

# Generate new file with our generator
echo "⚙️  Generating Insomnia file from OpenAPI spec..."
go run cmd/insomnia-generator/main.go -input "$OPENAPI_FILE" -output "$TEMP_FILE"

if [ ! -f "$TEMP_FILE" ]; then
    echo "❌ Error: Failed to generate temporary file"
    exit 1
fi

# If updating, replace the new IDs with original IDs
if [ "$UPDATE_MODE" = true ]; then
    echo "🔧 Restoring original IDs..."
    
    # Get new IDs from generated file
    NEW_WORKSPACE_ID=$(grep "id: wrk_" "$TEMP_FILE" | head -1 | sed 's/.*id: //' | tr -d ' ')
    NEW_FOLDER_ID=$(grep "id: fld_" "$TEMP_FILE" | head -1 | sed 's/.*id: //' | tr -d ' ')
    NEW_COOKIE_JAR_ID=$(grep "id: jar_" "$TEMP_FILE" | head -1 | sed 's/.*id: //' | tr -d ' ')
    NEW_ENV_ID=$(grep "id: env_" "$TEMP_FILE" | head -1 | sed 's/.*id: //' | tr -d ' ')
    NEW_SPEC_ID=$(grep "id: spc_" "$TEMP_FILE" | head -1 | sed 's/.*id: //' | tr -d ' ' || echo "")
    
    # Replace IDs in temp file
    sed -i.bak "s/$NEW_WORKSPACE_ID/$ORIGINAL_ID/g" "$TEMP_FILE"
    sed -i.bak "s/$NEW_FOLDER_ID/$FOLDER_ID/g" "$TEMP_FILE"
    sed -i.bak "s/$NEW_COOKIE_JAR_ID/$COOKIE_JAR_ID/g" "$TEMP_FILE"
    sed -i.bak "s/$NEW_ENV_ID/$ENV_ID/g" "$TEMP_FILE"
    
    if [ -n "$SPEC_ID" ] && [ -n "$NEW_SPEC_ID" ]; then
        sed -i.bak "s/$NEW_SPEC_ID/$SPEC_ID/g" "$TEMP_FILE"
    fi
    
    # Preserve the original creation timestamp
    NEW_CREATED=$(grep "created:" "$TEMP_FILE" | head -1 | sed 's/.*created: //' | tr -d ' ')
    sed -i.bak "s/created: $NEW_CREATED/created: $ORIGINAL_CREATED/" "$TEMP_FILE"
    
    # Clean up backup files
    rm -f "$TEMP_FILE.bak"
fi

# Replace/create the final file
echo "📝 Writing final Insomnia file..."
mv "$TEMP_FILE" "$INSOMNIA_FILE"

# Success message
if [ "$UPDATE_MODE" = true ]; then
    echo "✅ Successfully updated $INSOMNIA_FILE"
    echo "📋 Summary:"
    echo "   - Preserved original workspace ID: $ORIGINAL_ID"
    echo "   - Updated API endpoints from $OPENAPI_FILE"
    echo "   - Backup saved as: $BACKUP_FILE"
else
    echo "✅ Successfully created $INSOMNIA_FILE"
    echo "📋 Summary:"
    echo "   - Generated from OpenAPI spec: $OPENAPI_FILE"
    echo "   - Ready to import into Insomnia"
fi

echo ""
echo "🎉 Insomnia file is ready to use!" 