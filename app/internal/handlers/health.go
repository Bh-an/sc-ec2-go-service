package handlers

import (
	"encoding/json"
	"log/slog"
	"net/http"
)

func HealthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(map[string]string{"status": "ok"}); err != nil {
		slog.Error("encode health response", "error", err, "method", r.Method, "path", r.URL.Path)
		http.Error(w, "Internal Server Error", http.StatusInternalServerError)
	}
}
