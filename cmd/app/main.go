package main

import "github.com/trafilea/go-template/internal/routes"

func main() {
	routes.InitializeRouter().Run(":80")
}
