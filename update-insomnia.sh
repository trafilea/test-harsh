#!/bin/bash

# Update Insomnia File Script
# This script regenerates the Insomnia file while preserving original IDs and structure

set -e

OPENAPI_FILE="address.yml"
INSOMNIA_FILE="address_insomnia.yaml"
TEMP_FILE="temp-insomnia-update.yml"
BACKUP_FILE="${INSOMNIA_FILE}.backup"

echo "🔄 Updating Insomnia file from OpenAPI spec..."

# Check if files exist
if [ ! -f "$OPENAPI_FILE" ]; then
    echo "❌ Error: OpenAPI file '$OPENAPI_FILE' not found"
    exit 1
fi

if [ ! -f "$INSOMNIA_FILE" ]; then
    echo "❌ Error: Insomnia file '$INSOMNIA_FILE' not found"
    exit 1
fi

# Create backup of original file
echo "📦 Creating backup: $BACKUP_FILE"
cp "$INSOMNIA_FILE" "$BACKUP_FILE"

# Extract original metadata
echo "🔍 Extracting original metadata..."
ORIGINAL_ID=$(grep "id: wrk_" "$INSOMNIA_FILE" | head -1 | sed 's/.*id: //' | tr -d ' ')
ORIGINAL_CREATED=$(grep "created:" "$INSOMNIA_FILE" | head -1 | sed 's/.*created: //' | tr -d ' ')
FOLDER_ID=$(grep "id: fld_" "$INSOMNIA_FILE" | head -1 | sed 's/.*id: //' | tr -d ' ')
COOKIE_JAR_ID=$(grep "id: jar_" "$INSOMNIA_FILE" | head -1 | sed 's/.*id: //' | tr -d ' ')
ENV_ID=$(grep "id: env_" "$INSOMNIA_FILE" | head -1 | sed 's/.*id: //' | tr -d ' ')
SPEC_ID=$(grep "id: spc_" "$INSOMNIA_FILE" | head -1 | sed 's/.*id: //' | tr -d ' ')

echo "📝 Original IDs:"
echo "   Workspace: $ORIGINAL_ID"
echo "   Folder: $FOLDER_ID" 
echo "   Cookie Jar: $COOKIE_JAR_ID"
echo "   Environment: $ENV_ID"
echo "   Spec: $SPEC_ID"

# Generate new file with our generator
echo "⚙️  Generating updated Insomnia file..."
go run cmd/insomnia-generator/main.go -input "$OPENAPI_FILE" -output "$TEMP_FILE"

if [ ! -f "$TEMP_FILE" ]; then
    echo "❌ Error: Failed to generate temporary file"
    exit 1
fi

# Replace the new IDs with original IDs in the temp file
echo "🔧 Restoring original IDs..."
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

# Replace the original file with updated content
echo "📝 Updating original file..."
mv "$TEMP_FILE" "$INSOMNIA_FILE"

# Clean up
rm -f "$TEMP_FILE.bak"

echo "✅ Successfully updated $INSOMNIA_FILE"
echo "📋 Summary:"
echo "   - Preserved original workspace ID: $ORIGINAL_ID"
echo "   - Added/updated API endpoints from $OPENAPI_FILE"
echo "   - Backup saved as: $BACKUP_FILE"
echo ""
echo "🎉 Insomnia file is ready to use!" 