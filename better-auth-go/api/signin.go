package api

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/better-auth/better-auth-go/crypto"
	"github.com/better-auth/better-auth-go/types"
)

type signInBody struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

func (h *Handler) handleSignInEmail(w http.ResponseWriter, r *http.Request) {
	var body signInBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		h.errorResponse(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	if body.Email == "" || body.Password == "" {
		h.errorResponse(w, http.StatusBadRequest, "Missing email or password")
		return
	}

	// Find account
	account, err := h.Options.Adapter.GetAccount(r.Context(), "credential", body.Email)
	if err != nil {
		h.errorResponse(w, http.StatusInternalServerError, "Database error")
		return
	}
	if account == nil || account.Password == nil {
		h.errorResponse(w, http.StatusUnauthorized, "Invalid credentials")
		return
	}

	// Verify password
	if !crypto.VerifyPassword(body.Password, *account.Password) {
		h.errorResponse(w, http.StatusUnauthorized, "Invalid credentials")
		return
	}

	// Get user
	user, err := h.Options.Adapter.GetUser(r.Context(), account.UserID)
	if err != nil {
		h.errorResponse(w, http.StatusInternalServerError, "Database error")
		return
	}
	if user == nil {
		h.errorResponse(w, http.StatusUnauthorized, "User not found")
		return
	}

	// Create session
	sessionToken := crypto.GenerateID(32)
	expiresAt := time.Now().Add(7 * 24 * time.Hour)
	session := &types.Session{
		ID:        crypto.GenerateID(16),
		UserID:    user.ID,
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
		"user":    user,
		"session": createdSession,
	})
}
