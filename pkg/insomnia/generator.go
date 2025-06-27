package insomnia

import (
	"crypto/rand"
	"fmt"
	"os"
	"strings"
	"time"

	"gopkg.in/yaml.v3"
)

// InsomniaSpec represents the complete Insomnia workspace structure
type InsomniaSpec struct {
	Type         string           `yaml:"type"`
	Name         string           `yaml:"name"`
	Meta         Meta             `yaml:"meta"`
	Collection   []CollectionItem `yaml:"collection"`
	CookieJar    CookieJar        `yaml:"cookieJar"`
	Environments Environment      `yaml:"environments"`
	Spec         SpecContainer    `yaml:"spec"`
}

// Meta contains metadata for Insomnia items
type Meta struct {
	ID          string `yaml:"id"`
	Created     int64  `yaml:"created"`
	Modified    int64  `yaml:"modified"`
	Description string `yaml:"description,omitempty"`
	IsPrivate   bool   `yaml:"isPrivate,omitempty"`
	SortKey     int64  `yaml:"sortKey,omitempty"`
}

// CollectionItem represents a folder or request in the collection
type CollectionItem struct {
	Name     string        `yaml:"name"`
	Meta     Meta          `yaml:"meta"`
	Children []RequestItem `yaml:"children,omitempty"`
}

// RequestItem represents an individual API request
type RequestItem struct {
	URL      string          `yaml:"url"`
	Name     string          `yaml:"name"`
	Meta     Meta            `yaml:"meta"`
	Method   string          `yaml:"method"`
	Settings RequestSettings `yaml:"settings"`
}

// RequestSettings contains request configuration
type RequestSettings struct {
	RenderRequestBody bool           `yaml:"renderRequestBody"`
	EncodeURL         bool           `yaml:"encodeUrl"`
	FollowRedirects   string         `yaml:"followRedirects"`
	Cookies           CookieSettings `yaml:"cookies"`
	RebuildPath       bool           `yaml:"rebuildPath"`
}

// CookieSettings for request cookies
type CookieSettings struct {
	Send  bool `yaml:"send"`
	Store bool `yaml:"store"`
}

// CookieJar represents the cookie jar configuration
type CookieJar struct {
	Name string `yaml:"name"`
	Meta Meta   `yaml:"meta"`
}

// Environment represents the environment configuration
type Environment struct {
	Name            string           `yaml:"name"`
	Meta            Meta             `yaml:"meta"`
	Data            EnvironmentData  `yaml:"data"`
	SubEnvironments []SubEnvironment `yaml:"subEnvironments"`
}

// EnvironmentData contains environment variables
type EnvironmentData struct {
	BaseURL string `yaml:"base_url"`
}

// SubEnvironment represents a specific environment configuration
type SubEnvironment struct {
	Name string             `yaml:"name"`
	Meta Meta               `yaml:"meta"`
	Data SubEnvironmentData `yaml:"data"`
}

// SubEnvironmentData contains sub-environment specific data
type SubEnvironmentData struct {
	Scheme   string `yaml:"scheme"`
	BasePath string `yaml:"base_path"`
	Host     string `yaml:"host"`
}

// SpecContainer wraps the OpenAPI spec
type SpecContainer struct {
	Contents interface{} `yaml:"contents"`
	Meta     Meta        `yaml:"meta"`
}

// OpenAPISpec represents the structure we need from OpenAPI spec
type OpenAPISpec struct {
	OpenAPI string                 `yaml:"openapi"`
	Info    OpenAPIInfo            `yaml:"info"`
	Servers []OpenAPIServer        `yaml:"servers"`
	Paths   map[string]interface{} `yaml:"paths"`
	Tags    []OpenAPITag           `yaml:"tags,omitempty"`
}

// OpenAPIInfo contains API information
type OpenAPIInfo struct {
	Title       string          `yaml:"title"`
	Description string          `yaml:"description,omitempty"`
	Version     string          `yaml:"version"`
	Contact     *OpenAPIContact `yaml:"contact,omitempty"`
}

// OpenAPIContact contains contact information
type OpenAPIContact struct {
	Name  string `yaml:"name,omitempty"`
	Email string `yaml:"email,omitempty"`
}

// OpenAPIServer represents a server configuration
type OpenAPIServer struct {
	URL         string `yaml:"url"`
	Description string `yaml:"description,omitempty"`
}

// OpenAPITag represents an API tag
type OpenAPITag struct {
	Name        string `yaml:"name"`
	Description string `yaml:"description,omitempty"`
}

// Generator handles the conversion from OpenAPI to Insomnia format
type Generator struct {
	timestamp int64
}

// NewGenerator creates a new generator instance
func NewGenerator() *Generator {
	return &Generator{
		timestamp: time.Now().UnixMilli(),
	}
}

// GenerateFromOpenAPI converts an OpenAPI spec to Insomnia format
func (g *Generator) GenerateFromOpenAPI(openAPIData []byte) (*InsomniaSpec, error) {
	var openAPI OpenAPISpec
	if err := yaml.Unmarshal(openAPIData, &openAPI); err != nil {
		return nil, fmt.Errorf("failed to parse OpenAPI spec: %w", err)
	}

	// Parse the full spec as interface{} to preserve all data
	var fullSpec interface{}
	if err := yaml.Unmarshal(openAPIData, &fullSpec); err != nil {
		return nil, fmt.Errorf("failed to parse full OpenAPI spec: %w", err)
	}

	insomnia := &InsomniaSpec{
		Type: "spec.insomnia.rest/5.0",
		Name: fmt.Sprintf("%s %s", openAPI.Info.Title, openAPI.Info.Version),
		Meta: Meta{
			ID:          g.generateWorkspaceID(),
			Created:     g.timestamp,
			Modified:    g.timestamp - 1,
			Description: "",
		},
		Collection:   g.generateCollection(openAPI),
		CookieJar:    g.generateCookieJar(),
		Environments: g.generateEnvironments(openAPI),
		Spec: SpecContainer{
			Contents: fullSpec,
			Meta: Meta{
				ID:       g.generateSpecID(),
				Created:  g.timestamp + 3,
				Modified: g.timestamp + 4,
			},
		},
	}

	return insomnia, nil
}

// generateWorkspaceID generates a workspace ID
func (g *Generator) generateWorkspaceID() string {
	return fmt.Sprintf("wrk_%s", g.generateRandomID())
}

// generateSpecID generates a spec ID
func (g *Generator) generateSpecID() string {
	return fmt.Sprintf("spc_%s", g.generateRandomID())
}

// generateFolderID generates a folder ID
func (g *Generator) generateFolderID() string {
	return fmt.Sprintf("fld_%s", g.generateRandomID())
}

// generateRequestID generates a request ID
func (g *Generator) generateRequestID() string {
	return fmt.Sprintf("req_%s", g.generateRandomID())
}

// generateEnvironmentID generates an environment ID
func (g *Generator) generateEnvironmentID() string {
	return fmt.Sprintf("env_%s", g.generateRandomID())
}

// generateCookieJarID generates a cookie jar ID
func (g *Generator) generateCookieJarID() string {
	return fmt.Sprintf("jar_%s", g.generateRandomID())
}

// generateRandomID generates a random ID
func (g *Generator) generateRandomID() string {
	bytes := make([]byte, 16)
	if _, err := rand.Read(bytes); err != nil {
		// Fallback to timestamp-based ID
		return fmt.Sprintf("%d%d", g.timestamp, time.Now().Nanosecond())
	}
	return fmt.Sprintf("%x", bytes)
}

// generateCollection creates the collection structure from OpenAPI paths
func (g *Generator) generateCollection(openAPI OpenAPISpec) []CollectionItem {
	// Group requests by tags
	tagMap := make(map[string][]RequestItem)
	tagDescriptions := make(map[string]string)

	// Build tag descriptions map
	for _, tag := range openAPI.Tags {
		tagDescriptions[tag.Name] = tag.Description
	}

	sortKey := -g.timestamp

	// Process paths
	for path, pathItem := range openAPI.Paths {
		pathData, ok := pathItem.(map[string]interface{})
		if !ok {
			continue
		}

		for method, operation := range pathData {
			if method == "parameters" || method == "summary" || method == "description" {
				continue
			}

			opData, ok := operation.(map[string]interface{})
			if !ok {
				continue
			}

			// Extract operation details
			summary := g.getStringValue(opData, "summary")
			description := g.getStringValue(opData, "description")
			tags := g.getStringSlice(opData, "tags")

			if summary == "" {
				summary = fmt.Sprintf("%s %s", strings.ToUpper(method), path)
			}

			// Create request item
			request := RequestItem{
				URL:    g.buildURL(path, opData),
				Name:   summary,
				Method: strings.ToUpper(method),
				Meta: Meta{
					ID:          g.generateRequestID(),
					Created:     g.timestamp + 10,
					Modified:    g.timestamp + 10,
					IsPrivate:   false,
					Description: description,
					SortKey:     sortKey,
				},
				Settings: RequestSettings{
					RenderRequestBody: true,
					EncodeURL:         true,
					FollowRedirects:   "global",
					Cookies: CookieSettings{
						Send:  true,
						Store: true,
					},
					RebuildPath: true,
				},
			}

			// Assign to appropriate tag
			tag := "default"
			if len(tags) > 0 {
				tag = tags[0]
			}

			tagMap[tag] = append(tagMap[tag], request)
			sortKey++
		}
	}

	// Create collection items
	var collection []CollectionItem
	folderSortKey := -g.timestamp

	for tag, requests := range tagMap {
		description := tagDescriptions[tag]
		if description == "" {
			description = fmt.Sprintf("Operations related to %s", tag)
		}

		folder := CollectionItem{
			Name: tag,
			Meta: Meta{
				ID:          g.generateFolderID(),
				Created:     g.timestamp + 5,
				Modified:    g.timestamp + 5,
				SortKey:     folderSortKey,
				Description: description,
			},
			Children: requests,
		}

		collection = append(collection, folder)
		folderSortKey++
	}

	return collection
}

// buildURL constructs the URL with template variables
func (g *Generator) buildURL(path string, operation map[string]interface{}) string {
	baseURL := "{{ _.base_url }}"

	// Replace path parameters with template variables
	url := path
	if params, ok := operation["parameters"].([]interface{}); ok {
		for _, param := range params {
			if paramMap, ok := param.(map[string]interface{}); ok {
				if paramMap["in"] == "path" {
					paramName := paramMap["name"].(string)
					url = strings.ReplaceAll(url, fmt.Sprintf("{%s}", paramName), fmt.Sprintf("{{ _.%s }}", paramName))
				}
			}
		}
	}

	return baseURL + url
}

// generateCookieJar creates the cookie jar configuration
func (g *Generator) generateCookieJar() CookieJar {
	return CookieJar{
		Name: "Default Jar",
		Meta: Meta{
			ID:       g.generateCookieJarID(),
			Created:  g.timestamp - 5,
			Modified: g.timestamp - 5,
		},
	}
}

// generateEnvironments creates environment configurations from OpenAPI servers
func (g *Generator) generateEnvironments(openAPI OpenAPISpec) Environment {
	baseEnvID := g.generateEnvironmentID()

	env := Environment{
		Name: "Base Environment",
		Meta: Meta{
			ID:        baseEnvID,
			Created:   g.timestamp - 7,
			Modified:  g.timestamp + 8,
			IsPrivate: false,
		},
		Data: EnvironmentData{
			BaseURL: "{{ _.scheme }}://{{ _.host }}{{ _.base_path }}",
		},
		SubEnvironments: []SubEnvironment{},
	}

	// Create sub-environments from servers
	sortKey := g.timestamp + 9
	for _, server := range openAPI.Servers {
		scheme, host, basePath := g.parseServerURL(server.URL)

		subEnv := SubEnvironment{
			Name: fmt.Sprintf("OpenAPI env %s", host),
			Meta: Meta{
				ID:        g.generateEnvironmentID(),
				Created:   sortKey,
				Modified:  sortKey,
				IsPrivate: false,
				SortKey:   sortKey,
			},
			Data: SubEnvironmentData{
				Scheme:   scheme,
				BasePath: basePath,
				Host:     host,
			},
		}

		env.SubEnvironments = append(env.SubEnvironments, subEnv)
		sortKey++
	}

	return env
}

// parseServerURL extracts scheme, host, and base path from server URL
func (g *Generator) parseServerURL(serverURL string) (scheme, host, basePath string) {
	// Simple URL parsing - can be enhanced
	if strings.HasPrefix(serverURL, "https://") {
		scheme = "https"
		serverURL = strings.TrimPrefix(serverURL, "https://")
	} else if strings.HasPrefix(serverURL, "http://") {
		scheme = "http"
		serverURL = strings.TrimPrefix(serverURL, "http://")
	} else {
		scheme = "http"
	}

	parts := strings.SplitN(serverURL, "/", 2)
	host = parts[0]

	if len(parts) > 1 {
		basePath = "/" + parts[1]
	} else {
		basePath = ""
	}

	return
}

// Helper functions
func (g *Generator) getStringValue(data map[string]interface{}, key string) string {
	if val, ok := data[key].(string); ok {
		return val
	}
	return ""
}

func (g *Generator) getStringSlice(data map[string]interface{}, key string) []string {
	if val, ok := data[key].([]interface{}); ok {
		result := make([]string, 0, len(val))
		for _, item := range val {
			if str, ok := item.(string); ok {
				result = append(result, str)
			}
		}
		return result
	}
	return nil
}

// GenerateToFile generates Insomnia YAML and writes it to a file
func (g *Generator) GenerateToFile(openAPIFile, outputFile string) error {
	// Read OpenAPI file
	openAPIData, err := os.ReadFile(openAPIFile)
	if err != nil {
		return fmt.Errorf("failed to read OpenAPI file: %w", err)
	}

	// Generate Insomnia spec
	insomniaSpec, err := g.GenerateFromOpenAPI(openAPIData)
	if err != nil {
		return fmt.Errorf("failed to generate Insomnia spec: %w", err)
	}

	// Marshal to YAML
	yamlData, err := yaml.Marshal(insomniaSpec)
	if err != nil {
		return fmt.Errorf("failed to marshal Insomnia spec: %w", err)
	}

	// Write to file
	if err := os.WriteFile(outputFile, yamlData, 0644); err != nil {
		return fmt.Errorf("failed to write output file: %w", err)
	}

	return nil
}
