package main

import (
	"log"

	"github.com/evdzhurov/dist-services-with-go/proglog/internal/server"
)

func main() {
	srv := server.NewHTTPServer(":8080")
	log.Fatal(srv.ListenAndServe())
}
