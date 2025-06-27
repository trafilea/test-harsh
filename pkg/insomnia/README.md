# Insomnia Generator Package

This package provides utilities to automatically generate Insomnia workspace files from OpenAPI specifications.

## Features

- 🔄 **Automatic Generation**: Convert OpenAPI 3.x specs to Insomnia workspace format
- 👁️ **File Watching**: Monitor OpenAPI files and auto-regenerate Insomnia files when changes are detected
- 🏗️ **Complete Structure**: Generates all necessary Insomnia components (collections, environments, cookie jar, etc.)
- 🎯 **Accurate Mapping**: Preserves all OpenAPI details while creating proper Insomnia structure
- 📝 **Template Variables**: Automatically creates environment variables for dynamic configuration

## Package Structure

```
pkg/insomnia/
├── generator.go    # Core generation logic
├── watcher.go      # File watching functionality
└── README.md       # This documentation
```

## Core Components

### Generator

```go
type Generator struct {
    timestamp int64
}
```

The `Generator` handles the conversion from OpenAPI specifications to Insomnia format.

**Key Methods:**
- `NewGenerator()` - Creates a new generator instance
- `GenerateFromOpenAPI(data []byte)` - Converts OpenAPI data to Insomnia spec
- `GenerateToFile(input, output string)` - Reads OpenAPI file and writes Insomnia file

### FileWatcher

```go
type FileWatcher struct {
    generator      *Generator
    watchedFiles   map[string]string
    lastModified   map[string]time.Time
    pollInterval   time.Duration
}
```

The `FileWatcher` monitors OpenAPI files for changes and automatically regenerates Insomnia files.

**Key Methods:**
- `NewFileWatcher(interval time.Duration)` - Creates a new watcher
- `AddFile(openAPIFile, insomniaFile string)` - Adds a file to watch
- `StartWatching()` - Begins monitoring files
- `AutoDetectAndWatch(directory string)` - Auto-detects OpenAPI files in a directory

## OpenAPI to Insomnia Mapping

### File Structure Mapping

| OpenAPI Element | Insomnia Element | Description |
|----------------|------------------|-------------|
| `info.title + info.version` | `name` | Workspace name |
| `tags` | `collection` folders | API groups become folders |
| `paths` + operations | `collection` requests | Each operation becomes a request |
| `servers` | `subEnvironments` | Server configurations |
| Full OpenAPI spec | `spec.contents` | Complete spec preserved |

### Request Generation

Each OpenAPI operation becomes an Insomnia request with:
- **URL**: Base URL + path with template variables for parameters
- **Method**: HTTP method (GET, POST, etc.)
- **Name**: From operation `summary` or auto-generated
- **Description**: From operation `description`
- **Settings**: Default Insomnia request settings

### Environment Variables

The generator creates template variables for:
- `{{ _.base_url }}` - Base URL template
- `{{ _.scheme }}` - HTTP/HTTPS scheme
- `{{ _.host }}` - Server hostname
- `{{ _.base_path }}` - API base path
- `{{ _.paramName }}` - Path parameters

### ID Generation

All Insomnia elements get unique IDs:
- Workspace: `wrk_<random>`
- Folders: `fld_<random>`
- Requests: `req_<random>`
- Environments: `env_<random>`
- Cookie Jar: `jar_<random>`
- Spec: `spc_<random>`

## Usage Examples

### Basic Generation

```go
import "github.com/trafilea/go-template/pkg/insomnia"

// Create generator
generator := insomnia.NewGenerator()

// Generate from file
err := generator.GenerateToFile("api.yml", "api-insomnia.yml")
if err != nil {
    log.Fatal(err)
}
```

### File Watching

```go
import (
    "time"
    "github.com/trafilea/go-template/pkg/insomnia"
)

// Create watcher with 2-second polling
watcher := insomnia.NewFileWatcher(2 * time.Second)

// Add specific file
err := watcher.AddFile("api.yml", "api-insomnia.yml")
if err != nil {
    log.Fatal(err)
}

// Start watching (blocks)
watcher.StartWatching()
```

### Auto-Detection

```go
// Watch entire directory
watcher := insomnia.NewFileWatcher(2 * time.Second)
err := watcher.AutoDetectAndWatch("./api-specs")
if err != nil {
    log.Fatal(err)
}
```

## CLI Tools

The package includes two CLI utilities:

### insomnia-generator

One-time generation tool:

```bash
# Generate from specific file
go run cmd/insomnia-generator/main.go -input address.yml

# Generate with custom output
go run cmd/insomnia-generator/main.go -input address.yml -output my-insomnia.yml
```

### insomnia-watcher

Continuous monitoring tool:

```bash
# Watch current directory
go run cmd/insomnia-watcher/main.go

# Watch specific file
go run cmd/insomnia-watcher/main.go -file address.yml

# Watch directory with custom interval
go run cmd/insomnia-watcher/main.go -dir ./api-specs -interval 5
```

## Supported OpenAPI Features

### ✅ Fully Supported
- OpenAPI 3.x specifications
- Basic info (title, version, description)
- Server configurations
- Path operations (GET, POST, PUT, DELETE, PATCH)
- Path parameters
- Tags for organization
- Operation summaries and descriptions

### 🔄 Preserved but Not Processed
- Request/response schemas
- Security definitions
- Components and references
- Examples and samples

### ❌ Not Yet Supported
- Request body processing
- Query parameters as template variables
- Security configurations
- Response examples in requests

## File Format Requirements

### OpenAPI Files
- Must be YAML format (`.yml` or `.yaml`)
- Must contain `openapi:` version field
- Must have `info:` and `paths:` sections

### Output Files
- Generated as YAML in Insomnia format
- Compatible with Insomnia REST client
- Include all necessary metadata and IDs

## Error Handling

The package provides detailed error messages for:
- Invalid OpenAPI syntax
- Missing required fields
- File I/O issues
- YAML parsing errors

## Performance Considerations

- **Generation**: Fast for typical API specs (< 1 second)
- **Watching**: Polling-based, configurable interval
- **Memory**: Minimal footprint, processes files streaming
- **File Size**: Handles large OpenAPI specs efficiently

## Dependencies

```go
require (
    gopkg.in/yaml.v3 v3.0.1
)
```

## Contributing

When adding new features:
1. Maintain backward compatibility
2. Add comprehensive tests
3. Update documentation
4. Follow Go conventions
5. Handle errors gracefully

## Examples in Action

See the generated test file:
```bash
# Generate test file
go run cmd/insomnia-generator/main.go -input address.yml -output test-generated-insomnia.yml

# Compare with original
diff Address\ API\ 1.0.0-wrk_*.yaml test-generated-insomnia.yml
``` 