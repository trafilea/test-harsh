package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"

	"github.com/trafilea/go-template/pkg/insomnia"
)

func main() {
	var (
		openAPIFile = flag.String("input", "", "Path to OpenAPI spec file (required)")
		outputFile  = flag.String("output", "", "Output path for Insomnia file (optional, auto-generated if not provided)")
		help        = flag.Bool("help", false, "Show help message")
	)
	flag.Parse()

	if *help {
		showHelp()
		return
	}

	if *openAPIFile == "" {
		fmt.Println("Error: OpenAPI spec file is required")
		showHelp()
		os.Exit(1)
	}

	// Check if input file exists
	if _, err := os.Stat(*openAPIFile); os.IsNotExist(err) {
		log.Fatalf("OpenAPI file does not exist: %s", *openAPIFile)
	}

	// Generate output filename if not provided
	if *outputFile == "" {
		*outputFile = generateOutputFileName(*openAPIFile)
	}

	// Create generator and process file
	generator := insomnia.NewGenerator()

	fmt.Printf("Generating Insomnia file from OpenAPI spec...\n")
	fmt.Printf("Input:  %s\n", *openAPIFile)
	fmt.Printf("Output: %s\n", *outputFile)

	err := generator.GenerateToFile(*openAPIFile, *outputFile)
	if err != nil {
		log.Fatalf("Failed to generate Insomnia file: %v", err)
	}

	fmt.Printf("✅ Successfully generated Insomnia file: %s\n", *outputFile)
}

func showHelp() {
	fmt.Println("Insomnia Generator - Convert OpenAPI specs to Insomnia workspace files")
	fmt.Println("")
	fmt.Println("Usage:")
	fmt.Println("  insomnia-generator -input <openapi-file> [-output <insomnia-file>]")
	fmt.Println("")
	fmt.Println("Flags:")
	fmt.Println("  -input   Path to OpenAPI spec file (YAML format)")
	fmt.Println("  -output  Output path for Insomnia file (optional)")
	fmt.Println("  -help    Show this help message")
	fmt.Println("")
	fmt.Println("Examples:")
	fmt.Println("  insomnia-generator -input api.yml")
	fmt.Println("  insomnia-generator -input address.yml -output insomnia-address.yml")
}

func generateOutputFileName(inputFile string) string {
	// Get the base name without extension
	baseName := strings.TrimSuffix(filepath.Base(inputFile), filepath.Ext(inputFile))

	// Create output filename
	return fmt.Sprintf("%s-insomnia.yml", baseName)
}
