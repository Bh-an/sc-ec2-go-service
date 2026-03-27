package handlers

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	appversion "ec2-go-service/internal/version"
)

func TestVersionHandler(t *testing.T) {
	appversion.AppVersion = "vtest"
	appversion.GitCommit = "abcdef123456"
	appversion.BuildDate = "2026-03-27T00:00:00Z"

	req := httptest.NewRequest(http.MethodGet, "/version", nil)
	rec := httptest.NewRecorder()

	VersionHandler(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("unexpected status: got %d want %d", rec.Code, http.StatusOK)
	}

	var payload map[string]string
	if err := json.Unmarshal(rec.Body.Bytes(), &payload); err != nil {
		t.Fatalf("decode response: %v", err)
	}

	if payload["version"] != "vtest" {
		t.Fatalf("unexpected version payload: %q", payload["version"])
	}
	if payload["gitCommit"] != "abcdef123456" {
		t.Fatalf("unexpected commit payload: %q", payload["gitCommit"])
	}
	if payload["buildDate"] != "2026-03-27T00:00:00Z" {
		t.Fatalf("unexpected build date payload: %q", payload["buildDate"])
	}
}
