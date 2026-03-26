package handlers

import (
	"encoding/json"
	"log/slog"
	"net/http"
)

func RootHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)

	if err := json.NewEncoder(w).Encode(map[string]string{
		"service": "ec2-go-service",
		"status":  "ok",
	}); err != nil {
		slog.Error("encode root response", "error", err, "method", r.Method, "path", r.URL.Path)
	}
}
