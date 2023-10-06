package main

import (
	"fmt"

	backend "github.com/PatrickChoDev/WebsiteBackend/internal/app"
)

func main() {
	fmt.Println("Welcome to my backend app")
	backend.StartBackend()
}
