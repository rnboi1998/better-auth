package main

import (
	"log"
	"net/http"

	betterauth "github.com/better-auth/better-auth-go"
	"github.com/better-auth/better-auth-go/options"
	"github.com/better-auth/better-auth-go/plugins/logger"
)

func main() {
	// Initialize Better Auth
	auth := betterauth.New(&options.BetterAuthOptions{
		AppName: "My Demo App",
		BaseURL: "http://localhost:8080",
		BasePath: "/api/auth",
		Plugins: []options.Plugin{
			logger.NewLoggerPlugin(),
		},
	})

	// Mount the handler
	// Note: We mount at /api/auth/ to match the BasePath prefix
	http.Handle("/api/auth/", auth)

	// Add a protected route example
	http.HandleFunc("/api/protected", func(w http.ResponseWriter, r *http.Request) {
		// In a real app, you would use middleware to check session
		// Here we just manually call the session endpoint or check cookie
		// But for demo purposes, we can't easily call internal methods.
		// So we'll just say "Check /api/auth/get-session to see if you are logged in"
		w.Write([]byte("This is a protected route. Check /api/auth/get-session to verify your session."))
	})

	log.Println("Server started on http://localhost:8080")
	log.Println("Try:")
	log.Println("  POST /api/auth/sign-up/email { \"email\": \"test@example.com\", \"password\": \"password123\", \"name\": \"Test User\" }")
	log.Println("  POST /api/auth/sign-in/email { \"email\": \"test@example.com\", \"password\": \"password123\" }")
	log.Println("  GET  /api/auth/get-session")
	log.Println("  GET  /api/auth/logger/test")

	if err := http.ListenAndServe(":8080", nil); err != nil {
		log.Fatal(err)
	}
}
