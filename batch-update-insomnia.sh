#!/bin/bash

# Batch Update Insomnia Collections Script
# This script processes multiple OpenAPI specs and updates their Insomnia collections

set -e

echo "🔄 Batch updating all Insomnia files..."

# Configuration - Add your API files here
API_FILES=(
    "users.yml"
    "address.yml"
    # Add more API files as needed:
    # "orders-api.yml"
    # "inventory-api.yml"
    # "payments-api.yml"
)

# Counters for reporting
PROCESSED=0
SKIPPED=0
ERRORS=0

# Process each API file
for api in "${API_FILES[@]}"; do
    if [ -f "$api" ]; then
        # Generate output filename
        output_file="${api%.yml}_insomnia.yaml"
        
        echo "📝 Processing: $api → $output_file"
        
        # Run the update script
        if ./update-insomnia.sh -i "$api" -o "$output_file"; then
            echo "✅ Successfully processed: $api"
            ((PROCESSED++))
        else
            echo "❌ Failed to process: $api"
            ((ERRORS++))
        fi
        
        echo "" # Add spacing between files
    else
        echo "⚠️  Warning: $api not found, skipping..."
        ((SKIPPED++))
    fi
done

# Final report
echo "📊 Batch processing complete!"
echo "   ✅ Processed: $PROCESSED files"
echo "   ⚠️  Skipped: $SKIPPED files"
echo "   ❌ Errors: $ERRORS files"

if [ $ERRORS -gt 0 ]; then
    echo ""
    echo "🚨 Some files failed to process. Please check the errors above."
    exit 1
else
    echo ""
    echo "🎉 All files processed successfully!"
fi 