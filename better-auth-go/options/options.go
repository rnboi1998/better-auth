package options

import (
	"github.com/better-auth/better-auth-go/db"
)

// BetterAuthOptions holds the configuration for Better Auth.
type BetterAuthOptions struct {
	// AppName is the name of the application.
	AppName string
	// BaseURL is the base URL of the application.
	BaseURL string
	// BasePath is the path where Better Auth routes are mounted. Default is "/api/auth".
	BasePath string
	// Secret is used for encryption and hashing.
	Secret string
	// Database adapter.
	Adapter db.Adapter
	// EmailAndPassword configuration.
	EmailAndPassword *EmailAndPasswordOptions
}

// EmailAndPasswordOptions holds the configuration for email and password authentication.
type EmailAndPasswordOptions struct {
	Enabled                  bool
	MinPasswordLength        int
	MaxPasswordLength        int
	RequireEmailVerification bool
	AutoSignIn               bool
}
