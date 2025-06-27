package insomnia

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"
	"time"
)

// FileWatcher monitors OpenAPI files and regenerates Insomnia files when they change
type FileWatcher struct {
	generator    *Generator
	watchedFiles map[string]string // openapi file -> insomnia file mapping
	lastModified map[string]time.Time
	pollInterval time.Duration
}

// NewFileWatcher creates a new file watcher instance
func NewFileWatcher(pollInterval time.Duration) *FileWatcher {
	return &FileWatcher{
		generator:    NewGenerator(),
		watchedFiles: make(map[string]string),
		lastModified: make(map[string]time.Time),
		pollInterval: pollInterval,
	}
}

// AddFile adds an OpenAPI file to watch
func (w *FileWatcher) AddFile(openAPIFile, insomniaFile string) error {
	// Check if OpenAPI file exists
	if _, err := os.Stat(openAPIFile); os.IsNotExist(err) {
		return fmt.Errorf("OpenAPI file does not exist: %s", openAPIFile)
	}

	// Generate output filename if not provided
	if insomniaFile == "" {
		insomniaFile = generateInsomniaFileName(openAPIFile)
	}

	w.watchedFiles[openAPIFile] = insomniaFile

	// Get initial modification time
	if stat, err := os.Stat(openAPIFile); err == nil {
		w.lastModified[openAPIFile] = stat.ModTime()
	}

	log.Printf("Added file to watch: %s -> %s", openAPIFile, insomniaFile)
	return nil
}

// RemoveFile removes a file from being watched
func (w *FileWatcher) RemoveFile(openAPIFile string) {
	delete(w.watchedFiles, openAPIFile)
	delete(w.lastModified, openAPIFile)
	log.Printf("Removed file from watch: %s", openAPIFile)
}

// StartWatching begins monitoring files for changes
func (w *FileWatcher) StartWatching() {
	log.Printf("Starting file watcher with %d second polling interval", int(w.pollInterval.Seconds()))

	for {
		w.checkForChanges()
		time.Sleep(w.pollInterval)
	}
}

// checkForChanges checks all watched files for modifications
func (w *FileWatcher) checkForChanges() {
	for openAPIFile, insomniaFile := range w.watchedFiles {
		if w.hasFileChanged(openAPIFile) {
			log.Printf("Detected change in: %s", openAPIFile)

			if err := w.regenerateInsomniaFile(openAPIFile, insomniaFile); err != nil {
				log.Printf("Error regenerating Insomnia file: %v", err)
			} else {
				log.Printf("✅ Successfully regenerated: %s", insomniaFile)
			}
		}
	}
}

// hasFileChanged checks if a file has been modified since last check
func (w *FileWatcher) hasFileChanged(filePath string) bool {
	stat, err := os.Stat(filePath)
	if err != nil {
		log.Printf("Error checking file status for %s: %v", filePath, err)
		return false
	}

	lastMod, exists := w.lastModified[filePath]
	if !exists {
		w.lastModified[filePath] = stat.ModTime()
		return true
	}

	if stat.ModTime().After(lastMod) {
		w.lastModified[filePath] = stat.ModTime()
		return true
	}

	return false
}

// regenerateInsomniaFile regenerates the Insomnia file from OpenAPI spec
func (w *FileWatcher) regenerateInsomniaFile(openAPIFile, insomniaFile string) error {
	// Create a new generator for each regeneration to ensure fresh timestamps
	w.generator = NewGenerator()

	return w.generator.GenerateToFile(openAPIFile, insomniaFile)
}

// AutoDetectAndWatch automatically detects OpenAPI files and starts watching them
func (w *FileWatcher) AutoDetectAndWatch(directory string) error {
	// Walk through directory to find OpenAPI files
	err := filepath.Walk(directory, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		// Skip directories
		if info.IsDir() {
			return nil
		}

		// Check if file looks like an OpenAPI spec
		if w.isOpenAPIFile(path) {
			insomniaFile := generateInsomniaFileName(path)
			if err := w.AddFile(path, insomniaFile); err != nil {
				log.Printf("Warning: Could not add file to watch: %v", err)
			}
		}

		return nil
	})

	if err != nil {
		return fmt.Errorf("error walking directory: %w", err)
	}

	// Start watching if we found any files
	if len(w.watchedFiles) > 0 {
		log.Printf("Found %d OpenAPI files to watch", len(w.watchedFiles))
		w.StartWatching()
	} else {
		log.Printf("No OpenAPI files found in directory: %s", directory)
	}

	return nil
}

// isOpenAPIFile checks if a file appears to be an OpenAPI specification
func (w *FileWatcher) isOpenAPIFile(filePath string) bool {
	// Check file extension
	ext := strings.ToLower(filepath.Ext(filePath))
	if ext != ".yml" && ext != ".yaml" {
		return false
	}

	// Check file content for OpenAPI markers
	content, err := os.ReadFile(filePath)
	if err != nil {
		return false
	}

	contentStr := string(content)

	// Look for OpenAPI version markers
	return strings.Contains(contentStr, "openapi:") ||
		strings.Contains(contentStr, "swagger:") ||
		strings.Contains(contentStr, "info:") && strings.Contains(contentStr, "paths:")
}

// generateInsomniaFileName generates an Insomnia filename from OpenAPI filename
func generateInsomniaFileName(openAPIFile string) string {
	dir := filepath.Dir(openAPIFile)
	baseName := strings.TrimSuffix(filepath.Base(openAPIFile), filepath.Ext(openAPIFile))
	return filepath.Join(dir, fmt.Sprintf("%s-insomnia.yml", baseName))
}

// GetWatchedFiles returns a copy of the currently watched files
func (w *FileWatcher) GetWatchedFiles() map[string]string {
	result := make(map[string]string)
	for k, v := range w.watchedFiles {
		result[k] = v
	}
	return result
}
