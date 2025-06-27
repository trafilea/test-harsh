#!/bin/bash

# Create New API Specification Script
# This script helps create a new OpenAPI spec and Insomnia collection from template

set -e

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Create a new OpenAPI specification and Insomnia collection from template"
    echo ""
    echo "OPTIONS:"
    echo "  -n, --name NAME        API name (required, e.g., 'users', 'orders')"
    echo "  -p, --port PORT        Server port (default: 8080)"
    echo "  -d, --description DESC API description (optional)"
    echo "  -h, --help             Show this help message"
    echo ""
    echo "EXAMPLES:"
    echo "  $0 -n users -p 8082 -d 'User management API'"
    echo "  $0 -n orders -p 8083"
    echo "  $0 --name inventory --port 8084 --description 'Inventory management system'"
}

# Default values
API_NAME=""
PORT="8080"
DESCRIPTION=""
HELP=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--name)
            API_NAME="$2"
            shift 2
            ;;
        -p|--port)
            PORT="$2"
            shift 2
            ;;
        -d|--description)
            DESCRIPTION="$2"
            shift 2
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
if [ -z "$API_NAME" ]; then
    echo "❌ Error: API name is required"
    echo ""
    show_usage
    exit 1
fi

# Sanitize API name (remove spaces, convert to lowercase)
API_NAME_CLEAN=$(echo "$API_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')

# Set default description if not provided
if [ -z "$DESCRIPTION" ]; then
    DESCRIPTION="API endpoints for managing ${API_NAME}"
fi

# File names
OPENAPI_FILE="${API_NAME_CLEAN}-api.yml"
INSOMNIA_FILE="${API_NAME_CLEAN}-api_insomnia.yaml"

echo "🆕 Creating new API specification..."
echo "   📝 API Name: $API_NAME"
echo "   🌐 Port: $PORT"
echo "   📄 Description: $DESCRIPTION"
echo "   📁 OpenAPI File: $OPENAPI_FILE"
echo "   📁 Insomnia File: $INSOMNIA_FILE"
echo ""

# Check if files already exist
if [ -f "$OPENAPI_FILE" ]; then
    echo "❌ Error: $OPENAPI_FILE already exists"
    echo "   Please choose a different name or remove the existing file"
    exit 1
fi

# Create OpenAPI specification from template
echo "📝 Creating OpenAPI specification: $OPENAPI_FILE"

cat > "$OPENAPI_FILE" << EOF
openapi: 3.0.3
info:
  title: ${API_NAME} API
  description: ${DESCRIPTION}
  version: 1.0.0
  contact:
    name: API Support
    email: support@example.com

servers:
  - url: http://localhost:${PORT}/api/v1
    description: Local development server

paths:
  /${API_NAME_CLEAN}:
    get:
      summary: Get all ${API_NAME_CLEAN}
      description: Retrieves a list of all ${API_NAME_CLEAN}
      operationId: getAll$(echo ${API_NAME_CLEAN} | sed 's/\b\w/\U&/g' | sed 's/-//g')
      tags:
        - ${API_NAME_CLEAN}
      parameters:
        - name: limit
          in: query
          required: false
          description: Maximum number of items to return
          schema:
            type: integer
            minimum: 1
            maximum: 100
            default: 10
          example: 10
        - name: offset
          in: query
          required: false
          description: Number of items to skip for pagination
          schema:
            type: integer
            minimum: 0
            default: 0
          example: 0
      responses:
        '200':
          description: Successfully retrieved ${API_NAME_CLEAN}
          content:
            application/json:
              schema:
                type: object
                properties:
                  ${API_NAME_CLEAN}:
                    type: array
                    items:
                      \$ref: '#/components/schemas/$(echo ${API_NAME_CLEAN} | sed 's/\b\w/\U&/g' | sed 's/-//g' | sed 's/s$//')'
                  total:
                    type: integer
                    description: Total number of items
                    example: 100
                  limit:
                    type: integer
                    description: Limit applied to the request
                    example: 10
                  offset:
                    type: integer
                    description: Offset applied to the request
                    example: 0
        '400':
          description: Invalid query parameters
          content:
            application/json:
              schema:
                \$ref: '#/components/schemas/ErrorResponse'
        '500':
          description: Internal server error
          content:
            application/json:
              schema:
                \$ref: '#/components/schemas/ErrorResponse'

  /${API_NAME_CLEAN}/{id}:
    get:
      summary: Get $(echo ${API_NAME_CLEAN} | sed 's/s$//' | sed 's/\b\w/\U&/g' | sed 's/-//g') by ID
      description: Retrieves a specific $(echo ${API_NAME_CLEAN} | sed 's/s$//') by ID
      operationId: get$(echo ${API_NAME_CLEAN} | sed 's/\b\w/\U&/g' | sed 's/-//g' | sed 's/s$//')ById
      tags:
        - ${API_NAME_CLEAN}
      parameters:
        - name: id
          in: path
          required: true
          description: Unique identifier
          schema:
            type: integer
            format: int64
            minimum: 1
          example: 1
      responses:
        '200':
          description: Successfully retrieved $(echo ${API_NAME_CLEAN} | sed 's/s$//')
          content:
            application/json:
              schema:
                \$ref: '#/components/schemas/$(echo ${API_NAME_CLEAN} | sed 's/\b\w/\U&/g' | sed 's/-//g' | sed 's/s$//')'
        '400':
          description: Invalid ID provided
          content:
            application/json:
              schema:
                \$ref: '#/components/schemas/ErrorResponse'
        '404':
          description: $(echo ${API_NAME_CLEAN} | sed 's/s$//' | sed 's/\b\w/\U&/g' | sed 's/-//g') not found
          content:
            application/json:
              schema:
                \$ref: '#/components/schemas/ErrorResponse'
        '500':
          description: Internal server error
          content:
            application/json:
              schema:
                \$ref: '#/components/schemas/ErrorResponse'

components:
  schemas:
    $(echo ${API_NAME_CLEAN} | sed 's/\b\w/\U&/g' | sed 's/-//g' | sed 's/s$//'):
      type: object
      description: $(echo ${API_NAME_CLEAN} | sed 's/s$//' | sed 's/\b\w/\U&/g' | sed 's/-//g') details
      required:
        - id
        - name
      properties:
        id:
          type: integer
          format: int64
          description: Unique identifier
          example: 1
        name:
          type: string
          description: Name of the $(echo ${API_NAME_CLEAN} | sed 's/s$//')
          example: "Sample $(echo ${API_NAME_CLEAN} | sed 's/s$//' | sed 's/\b\w/\U&/g' | sed 's/-/ /g')"
        # TODO: Add more properties as needed

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
          example: "$(echo ${API_NAME_CLEAN} | sed 's/s$//' | sed 's/\b\w/\U&/g' | sed 's/-/ /g') not found"

tags:
  - name: ${API_NAME_CLEAN}
    description: Operations related to ${API_NAME_CLEAN}
EOF

echo "✅ Created OpenAPI specification: $OPENAPI_FILE"

# Generate Insomnia collection
echo "📝 Generating Insomnia collection: $INSOMNIA_FILE"

if ./update-insomnia.sh -i "$OPENAPI_FILE" -o "$INSOMNIA_FILE"; then
    echo "✅ Created Insomnia collection: $INSOMNIA_FILE"
else
    echo "❌ Failed to create Insomnia collection"
    echo "   The OpenAPI file was created successfully, but Insomnia generation failed"
    echo "   You can try running: ./update-insomnia.sh -i $OPENAPI_FILE -o $INSOMNIA_FILE"
    exit 1
fi

echo ""
echo "🎉 Successfully created new API specification!"
echo ""
echo "📋 Next Steps:"
echo "   1. Edit $OPENAPI_FILE to customize your API endpoints"
echo "   2. Add more properties to the schema as needed"
echo "   3. Run './update-insomnia.sh -i $OPENAPI_FILE -o $INSOMNIA_FILE' after changes"
echo "   4. Import $INSOMNIA_FILE into Insomnia for testing"
echo ""
echo "📚 For more information, see: TEAM_WORKFLOW_TEMPLATE.md" 