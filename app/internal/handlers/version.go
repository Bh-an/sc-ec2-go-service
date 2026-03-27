package handlers

import (
	"encoding/json"
	"log/slog"
	"net/http"

	"ec2-go-service/internal/models"
	appversion "ec2-go-service/internal/version"
)

func VersionHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	response := models.VersionResponse{
		Version:   appversion.AppVersion,
		GitCommit: appversion.GitCommit,
		BuildDate: appversion.BuildDate,
	}
	if err := json.NewEncoder(w).Encode(response); err != nil {
		slog.Error("encode version response", "error", err, "method", r.Method, "path", r.URL.Path)
		http.Error(w, "Internal Server Error", http.StatusInternalServerError)
	}
}
