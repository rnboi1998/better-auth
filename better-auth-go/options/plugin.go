package options

import (
	"net/http"
)

// Plugin defines a Better Auth plugin.
type Plugin struct {
	ID        string
	Endpoints map[string]http.HandlerFunc
}
