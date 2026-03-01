package api

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/better-auth/better-auth-go/crypto"
	"github.com/better-auth/better-auth-go/types"
)

type signUpBody struct {
	Email    string  `json:"email"`
	Password string  `json:"password"`
	Name     string  `json:"name"`
	Image    *string `json:"image"`
}

func (h *Handler) handleSignUpEmail(w http.ResponseWriter, r *http.Request) {
	var body signUpBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		h.errorResponse(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	if body.Email == "" || body.Password == "" || body.Name == "" {
		h.errorResponse(w, http.StatusBadRequest, "Missing required fields")
		return
	}

	// Check if user exists
	existingUser, err := h.Options.Adapter.GetUserByEmail(r.Context(), body.Email)
	if err != nil {
		h.errorResponse(w, http.StatusInternalServerError, "Database error")
		return
	}
	if existingUser != nil {
		h.errorResponse(w, http.StatusConflict, "User already exists")
		return
	}

	// Hash password
	hashedPassword, err := crypto.HashPassword(body.Password)
	if err != nil {
		h.errorResponse(w, http.StatusInternalServerError, "Failed to hash password")
		return
	}

	// Create user
	userID := crypto.GenerateID(16)
	user := &types.User{
		ID:            userID,
		Email:         body.Email,
		EmailVerified: false,
		Name:          body.Name,
		Image:         body.Image,
	}

	createdUser, err := h.Options.Adapter.CreateUser(r.Context(), user)
	if err != nil {
		h.errorResponse(w, http.StatusInternalServerError, "Failed to create user")
		return
	}

	// Create account
	account := &types.Account{
		ID:         crypto.GenerateID(16),
		UserID:     userID,
		AccountID:  body.Email,
		ProviderID: "credential",
		Password:   &hashedPassword,
	}

	_, err = h.Options.Adapter.CreateAccount(r.Context(), account)
	if err != nil {
		// Rollback user creation? For simplicity, we skip rollback logic here
		h.errorResponse(w, http.StatusInternalServerError, "Failed to create account")
		return
	}

	// Create session
	sessionToken := crypto.GenerateID(32)
	expiresAt := time.Now().Add(7 * 24 * time.Hour) // 7 days
	session := &types.Session{
		ID:        crypto.GenerateID(16),
		UserID:    userID,
		Token:     sessionToken,
		ExpiresAt: expiresAt,
		UserAgent: getStringPointer(r.UserAgent()),
		IPAddress: getStringPointer(r.RemoteAddr),
	}

	createdSession, err := h.Options.Adapter.CreateSession(r.Context(), session)
	if err != nil {
		h.errorResponse(w, http.StatusInternalServerError, "Failed to create session")
		return
	}

	// Set cookie
	http.SetCookie(w, &http.Cookie{
		Name:     "better-auth.session_token",
		Value:    sessionToken,
		Path:     "/",
		Expires:  expiresAt,
		HttpOnly: true,
		Secure:   r.TLS != nil || r.Header.Get("X-Forwarded-Proto") == "https",
		SameSite: http.SameSiteLaxMode,
	})

	h.jsonResponse(w, http.StatusOK, map[string]interface{}{
		"user":    createdUser,
		"session": createdSession,
	})
}

func getStringPointer(s string) *string {
	if s == "" {
		return nil
	}
	return &s
}
