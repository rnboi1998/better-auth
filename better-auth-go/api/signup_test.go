package api

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/better-auth/better-auth-go/options"
	"github.com/better-auth/better-auth-go/db/memory"
)

func TestSignUp(t *testing.T) {
	opts := &options.BetterAuthOptions{
		Adapter: memory.NewMemoryAdapter(),
	}
	handler := NewHandler(opts)

	body := map[string]string{
		"email":    "test@example.com",
		"password": "password123",
		"name":     "Test User",
	}
	jsonBody, _ := json.Marshal(body)

	req := httptest.NewRequest("POST", "/api/auth/sign-up/email", bytes.NewBuffer(jsonBody))
	w := httptest.NewRecorder()

	handler.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("Expected status OK, got %v", w.Code)
	}

	var response map[string]interface{}
	if err := json.NewDecoder(w.Body).Decode(&response); err != nil {
		t.Fatalf("Failed to decode response: %v", err)
	}

	if response["user"] == nil {
		t.Error("Expected user in response")
	}
	if response["session"] == nil {
		t.Error("Expected session in response")
	}
}
