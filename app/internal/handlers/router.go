package handlers

import "net/http"

func NewMux() *http.ServeMux {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /api/v1", APIHandler)
	mux.HandleFunc("GET /health", HealthHandler)
	mux.HandleFunc("GET /version", VersionHandler)
	return mux
}
