package handlers

import (
	"encoding/json"
	"log/slog"
	"math/rand/v2"
	"net/http"

	"ec2-go-service/internal/models"
)

var words = []string{
	"Investments",
	"Portfolio",
	"Stocks",
	"buy-the-dip",
	"TickerTape",
}

func APIHandler(w http.ResponseWriter, r *http.Request) {
	word := words[rand.IntN(len(words))]

	w.Header().Set("Content-Type", "application/json")

	response := models.APIResponse{Message: word}
	if err := json.NewEncoder(w).Encode(response); err != nil {
		slog.Error("encode api response", "error", err, "method", r.Method, "path", r.URL.Path)
		http.Error(w, "Internal Server Error", http.StatusInternalServerError)
		return
	}

	slog.Info("served api request", "method", r.Method, "path", r.URL.Path, "word", word)
}
