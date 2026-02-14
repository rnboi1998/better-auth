package betterauth

import (
	"net/http"

	"github.com/better-auth/better-auth-go/api"
	"github.com/better-auth/better-auth-go/db/memory"
	"github.com/better-auth/better-auth-go/options"
)

// BetterAuth is the main struct for Better Auth.
type BetterAuth struct {
	Options *options.BetterAuthOptions
	Handler *api.Handler
}

// New creates a new BetterAuth instance.
func New(opts *options.BetterAuthOptions) *BetterAuth {
	if opts == nil {
		opts = &options.BetterAuthOptions{}
	}

	if opts.Adapter == nil {
		// Default to memory adapter if none provided
		opts.Adapter = memory.NewMemoryAdapter()
	}

	if opts.BasePath == "" {
		opts.BasePath = "/api/auth"
	}

	return &BetterAuth{
		Options: opts,
		Handler: api.NewHandler(opts),
	}
}

// ServeHTTP satisfies the http.Handler interface.
func (b *BetterAuth) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	b.Handler.ServeHTTP(w, r)
}
