package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/trafilea/go-template/pkg/insomnia"
)

func main() {
	var (
		directory = flag.String("dir", ".", "Directory to watch for OpenAPI files")
		interval  = flag.Int("interval", 2, "Polling interval in seconds")
		file      = flag.String("file", "", "Specific OpenAPI file to watch (optional)")
		output    = flag.String("output", "", "Output file for specific file watching (optional)")
		help      = flag.Bool("help", false, "Show help message")
	)
	flag.Parse()

	if *help {
		showHelp()
		return
	}

	// Create file watcher
	watcher := insomnia.NewFileWatcher(time.Duration(*interval) * time.Second)

	// Set up signal handling for graceful shutdown
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	if *file != "" {
		// Watch specific file
		fmt.Printf("Setting up watcher for specific file: %s\n", *file)
		if err := watcher.AddFile(*file, *output); err != nil {
			log.Fatalf("Failed to add file to watcher: %v", err)
		}

		fmt.Printf("Watching file: %s\n", *file)
		if *output != "" {
			fmt.Printf("Output file: %s\n", *output)
		}
		fmt.Printf("Polling interval: %d seconds\n", *interval)
		fmt.Println("Press Ctrl+C to stop watching...")

		// Start watching in a goroutine
		go watcher.StartWatching()
	} else {
		// Auto-detect and watch directory
		fmt.Printf("Setting up auto-detection for directory: %s\n", *directory)
		fmt.Printf("Polling interval: %d seconds\n", *interval)
		fmt.Println("Press Ctrl+C to stop watching...")

		// Start auto-detection in a goroutine
		go func() {
			if err := watcher.AutoDetectAndWatch(*directory); err != nil {
				log.Printf("Error in auto-detection: %v", err)
			}
		}()
	}

	// Wait for interrupt signal
	<-sigChan
	fmt.Println("\n🛑 Shutting down watcher...")

	// Show final status
	watchedFiles := watcher.GetWatchedFiles()
	if len(watchedFiles) > 0 {
		fmt.Printf("📊 Final status - watched %d files:\n", len(watchedFiles))
		for openapi, insomnia := range watchedFiles {
			fmt.Printf("  %s → %s\n", openapi, insomnia)
		}
	}

	fmt.Println("👋 Goodbye!")
}

func showHelp() {
	fmt.Println("Insomnia Watcher - Monitor OpenAPI files and auto-generate Insomnia workspaces")
	fmt.Println("")
	fmt.Println("Usage:")
	fmt.Println("  # Watch entire directory for OpenAPI files")
	fmt.Println("  insomnia-watcher [-dir <directory>] [-interval <seconds>]")
	fmt.Println("")
	fmt.Println("  # Watch specific file")
	fmt.Println("  insomnia-watcher -file <openapi-file> [-output <insomnia-file>] [-interval <seconds>]")
	fmt.Println("")
	fmt.Println("Flags:")
	fmt.Println("  -dir      Directory to watch for OpenAPI files (default: current directory)")
	fmt.Println("  -file     Specific OpenAPI file to watch")
	fmt.Println("  -output   Output Insomnia file (only used with -file)")
	fmt.Println("  -interval Polling interval in seconds (default: 2)")
	fmt.Println("  -help     Show this help message")
	fmt.Println("")
	fmt.Println("Examples:")
	fmt.Println("  # Watch current directory")
	fmt.Println("  insomnia-watcher")
	fmt.Println("")
	fmt.Println("  # Watch specific directory with 5-second interval")
	fmt.Println("  insomnia-watcher -dir ./api-specs -interval 5")
	fmt.Println("")
	fmt.Println("  # Watch specific file")
	fmt.Println("  insomnia-watcher -file address.yml")
	fmt.Println("")
	fmt.Println("  # Watch specific file with custom output")
	fmt.Println("  insomnia-watcher -file address.yml -output my-insomnia.yml")
	fmt.Println("")
	fmt.Println("Notes:")
	fmt.Println("  - Supported file extensions: .yml, .yaml")
	fmt.Println("  - Auto-detection looks for files containing 'openapi:', 'swagger:', or 'info:' + 'paths:'")
	fmt.Println("  - Generated Insomnia files have '-insomnia.yml' suffix by default")
	fmt.Println("  - Use Ctrl+C to stop the watcher")
}
