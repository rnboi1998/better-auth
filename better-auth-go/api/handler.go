package api

import (
	"encoding/json"
	"net/http"
	"strings"

	"github.com/better-auth/better-auth-go/options"
)

// Handler handles authentication requests.
type Handler struct {
	Options *options.BetterAuthOptions
	Routes  map[string]http.HandlerFunc
}

// NewHandler creates a new Handler.
func NewHandler(options *options.BetterAuthOptions) *Handler {
	h := &Handler{
		Options: options,
		Routes:  make(map[string]http.HandlerFunc),
	}
	h.registerRoutes()
	return h
}

// ServeHTTP satisfies the http.Handler interface.
func (h *Handler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	// Simple routing based on path suffix

	basePath := h.Options.BasePath
	if basePath == "" {
		basePath = "/api/auth"
	}

	path := r.URL.Path
	if !strings.HasPrefix(path, basePath) {
		http.NotFound(w, r)
		return
	}

	relativePath := strings.TrimPrefix(path, basePath)
	// Remove leading slash if present
	if strings.HasPrefix(relativePath, "/") {
		relativePath = relativePath[1:]
	}

	// Add leading slash for map lookup
	relativePath = "/" + relativePath

	if handler, ok := h.Routes[relativePath]; ok {
		handler(w, r)
		return
	}

	http.NotFound(w, r)
}

func (h *Handler) jsonResponse(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}

func (h *Handler) errorResponse(w http.ResponseWriter, status int, message string) {
	h.jsonResponse(w, status, map[string]string{"error": message})
}
