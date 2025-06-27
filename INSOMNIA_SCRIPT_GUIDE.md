# Insomnia File Generator Script Guide

This guide explains how to use the `update-insomnia.sh` script to create and update Insomnia collection files from OpenAPI specifications.

## Overview

The `update-insomnia.sh` script is a flexible tool that can:
- **Create new** Insomnia collection files from OpenAPI specs
- **Update existing** Insomnia files while preserving workspace IDs and metadata
- **Overwrite existing** files when needed

## Prerequisites

1. **Go installed** - The script uses the Go insomnia-generator tool
2. **Project structure** - Must be run from the project root directory
3. **Insomnia generator** - The tool at `cmd/insomnia-generator/main.go` must exist

## Usage

### Basic Syntax
```bash
./update-insomnia.sh [OPTIONS]
```

### Options

| Option | Long Form | Description | Required |
|--------|-----------|-------------|----------|
| `-i` | `--input` | OpenAPI specification file path | ✅ Yes |
| `-o` | `--output` | Insomnia output file path | ✅ Yes |
| `-c` | `--create` | Force create mode (overwrite existing) | ❌ No |
| `-h` | `--help` | Show help message and examples | ❌ No |

## Examples

### 1. Create New Insomnia File
When the output file doesn't exist, the script automatically creates a new one:

```bash
./update-insomnia.sh -i users.yml -o users_insomnia.yaml
```

**Output:**
```
🆕 Creating new Insomnia file: users_insomnia.yaml
⚙️  Generating Insomnia file from OpenAPI spec...
📝 Writing final Insomnia file...
✅ Successfully created users_insomnia.yaml
📋 Summary:
   - Generated from OpenAPI spec: users.yml
   - Ready to import into Insomnia
```

### 2. Update Existing Insomnia File
When the output file exists, the script preserves IDs and metadata:

```bash
./update-insomnia.sh -i address.yml -o address_insomnia.yaml
```

**Output:**
```
🔄 Updating existing Insomnia file: address_insomnia.yaml
📦 Creating backup: address_insomnia.yaml.backup
🔍 Extracting original metadata...
📝 Original IDs:
   Workspace: wrk_40d19e55fc174fb5a8585ae34f8f564f
   Folder: fld_1ce885658947413caee63a9c55a71430
   Cookie Jar: jar_b80e364e9488b026ad6f2f58d668708e208ac00e
   Environment: env_b80e364e9488b026ad6f2f58d668708e208ac00e
⚙️  Generating Insomnia file from OpenAPI spec...
🔧 Restoring original IDs...
📝 Writing final Insomnia file...
✅ Successfully updated address_insomnia.yaml
📋 Summary:
   - Preserved original workspace ID: wrk_40d19e55fc174fb5a8585ae34f8f564f
   - Updated API endpoints from address.yml
   - Backup saved as: address_insomnia.yaml.backup
```

### 3. Force Create (Overwrite Existing)
Use the `--create` flag to overwrite an existing file with completely new content:

```bash
./update-insomnia.sh -i api.yml -o api_insomnia.yaml --create
```

**Output:**
```
🆕 Creating new Insomnia file (overwriting existing): api_insomnia.yaml
⚙️  Generating Insomnia file from OpenAPI spec...
📝 Writing final Insomnia file...
✅ Successfully created api_insomnia.yaml
```

### 4. Show Help
```bash
./update-insomnia.sh --help
```

## File Management

### Backup Files
When updating existing files, the script automatically creates backups:
- **Backup location**: `{original_filename}.backup`
- **Example**: `address_insomnia.yaml.backup`
- **Contains**: Complete copy of the original file before changes

### Temporary Files
The script uses temporary files during processing:
- **Pattern**: `temp-insomnia-{timestamp}.yml`
- **Cleanup**: Automatically removed after successful completion

## Behavior Modes

### Auto-Detection Mode (Default)
The script automatically detects whether to create or update:

| Scenario | Action | Description |
|----------|--------|-------------|
| Output file doesn't exist | **Create** | Generate new Insomnia file |
| Output file exists | **Update** | Preserve IDs, update content |

### Force Create Mode (`--create`)
Override auto-detection to always create new files:

| Scenario | Action | Description |
|----------|--------|-------------|
| Output file doesn't exist | **Create** | Generate new Insomnia file |
| Output file exists | **Create** | Overwrite with new file (new IDs) |

## ID Preservation

When updating existing files, the script preserves these important identifiers:

| ID Type | Purpose | Example |
|---------|---------|---------|
| Workspace ID | Main workspace identifier | `wrk_40d19e55fc174fb5a8585ae34f8f564f` |
| Folder ID | Collection folder identifier | `fld_1ce885658947413caee63a9c55a71430` |
| Cookie Jar ID | Cookie storage identifier | `jar_b80e364e9488b026ad6f2f58d668708e208ac00e` |
| Environment ID | Environment settings identifier | `env_b80e364e9488b026ad6f2f58d668708e208ac00e` |
| Creation Time | Original file creation timestamp | `1750970987604` |

## Error Handling

### Common Errors and Solutions

#### Missing Input File
```
❌ Error: OpenAPI file 'missing.yml' not found
```
**Solution**: Check the file path and ensure the OpenAPI file exists.

#### Missing Required Arguments
```
❌ Error: Both input and output files are required
```
**Solution**: Provide both `-i` (input) and `-o` (output) arguments.

#### Missing Generator Tool
```
❌ Error: Insomnia generator not found at 'cmd/insomnia-generator/main.go'
   Make sure you're running this script from the project root
```
**Solution**: Run the script from the project root directory where the generator exists.

#### Generation Failure
```
❌ Error: Failed to generate temporary file
```
**Solution**: Check that the OpenAPI file is valid and the Go generator tool is working.

## Best Practices

### 1. Always Run from Project Root
```bash
# Correct - from project root
./update-insomnia.sh -i users.yml -o users_insomnia.yaml

# Incorrect - from subdirectory
cd some/folder
../../update-insomnia.sh -i users.yml -o users_insomnia.yaml
```

### 2. Use Descriptive File Names
```bash
# Good naming convention
./update-insomnia.sh -i users-api.yml -o users-api_insomnia.yaml
./update-insomnia.sh -i orders-v2.yml -o orders-v2_insomnia.yaml
```

### 3. Keep Backups Safe
- Backup files are created automatically during updates
- Consider version control for important Insomnia collections
- Archive old backups periodically

### 4. Validate OpenAPI Files First
Before running the script, ensure your OpenAPI file is valid:
```bash
# Use tools like swagger-codegen or openapi-generator to validate
swagger-codegen validate -i your-api.yml
```

## Integration with Insomnia

### Importing Generated Files

1. **Open Insomnia**
2. **Go to**: Application Menu → Import/Export → Import Data
3. **Select**: From File
4. **Choose**: Your generated `*_insomnia.yaml` file
5. **Import**: The collection will be added to your workspace

### Updating Existing Collections

When you update an existing Insomnia file:
1. The collection in Insomnia will automatically reflect changes
2. No need to re-import if using the same workspace ID
3. Existing request history and customizations are preserved

## Troubleshooting

### Script Permission Issues
```bash
# Make script executable
chmod +x update-insomnia.sh
```

### Go Module Issues
```bash
# Ensure Go modules are initialized
go mod tidy
```

### YAML Parsing Issues
- Ensure proper YAML formatting in OpenAPI files
- Check for indentation errors
- Validate YAML syntax using online tools

## Advanced Usage

### Batch Processing Multiple APIs
```bash
#!/bin/bash
# Process multiple API specs
for api in users orders products; do
    ./update-insomnia.sh -i "${api}.yml" -o "${api}_insomnia.yaml"
done
```

### Integration with CI/CD
```bash
# In your CI/CD pipeline
./update-insomnia.sh -i api/openapi.yml -o insomnia/api_collection.yaml
# Commit the updated collection back to repository
```

## Support

For issues or questions:
1. Check this guide first
2. Verify prerequisites are met
3. Review error messages for specific guidance
4. Check that file paths are correct and files exist

---

*This script is designed to work with the project's specific insomnia-generator tool. Ensure all dependencies are properly installed and the project structure is maintained.* 