package api

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/better-auth/better-auth-go/options"
	"github.com/better-auth/better-auth-go/db/memory"
)

func TestPlugin(t *testing.T) {
	plugin := options.Plugin{
		ID: "test-plugin",
		Endpoints: map[string]http.HandlerFunc{
			"/test-plugin/hello": func(w http.ResponseWriter, r *http.Request) {
				w.Write([]byte("Hello from plugin"))
			},
		},
	}

	opts := &options.BetterAuthOptions{
		Adapter: memory.NewMemoryAdapter(),
		Plugins: []options.Plugin{plugin},
	}
	handler := NewHandler(opts)

	// Note: BasePath defaults to /api/auth
	req := httptest.NewRequest("GET", "/api/auth/test-plugin/hello", nil)
	w := httptest.NewRecorder()

	handler.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("Expected status OK, got %v", w.Code)
	}

	if w.Body.String() != "Hello from plugin" {
		t.Errorf("Expected 'Hello from plugin', got '%s'", w.Body.String())
	}
}
