package logger

import (
	"encoding/json"
	"net/http"

	"github.com/better-auth/better-auth-go/options"
)

// NewLoggerPlugin creates a new logger plugin.
func NewLoggerPlugin() options.Plugin {
	return options.Plugin{
		ID: "logger",
		Endpoints: map[string]http.HandlerFunc{
			"/logger/test": func(w http.ResponseWriter, r *http.Request) {
				w.Header().Set("Content-Type", "application/json")
				json.NewEncoder(w).Encode(map[string]string{
					"message": "Logger plugin active",
				})
			},
		},
	}
}
