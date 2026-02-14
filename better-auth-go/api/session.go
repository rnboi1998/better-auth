package api

import (
	"net/http"
	"strings"
	"time"
)

func (h *Handler) handleGetSession(w http.ResponseWriter, r *http.Request) {
	// Get token from cookie
	cookie, err := r.Cookie("better-auth.session_token")
	var token string
	if err == nil {
		token = cookie.Value
	} else {
		// Get token from header
		authHeader := r.Header.Get("Authorization")
		if authHeader != "" && strings.HasPrefix(authHeader, "Bearer ") {
			token = authHeader[7:]
		}
	}

	if token == "" {
		h.errorResponse(w, http.StatusUnauthorized, "Missing session token")
		return
	}

	// Verify session
	session, err := h.Options.Adapter.GetSession(r.Context(), token)
	if err != nil {
		h.errorResponse(w, http.StatusInternalServerError, "Database error")
		return
	}
	if session == nil {
		h.errorResponse(w, http.StatusUnauthorized, "Invalid session")
		return
	}

	if session.ExpiresAt.Before(time.Now()) {
		h.errorResponse(w, http.StatusUnauthorized, "Session expired")
		return
	}

	// Get user
	user, err := h.Options.Adapter.GetUser(r.Context(), session.UserID)
	if err != nil {
		h.errorResponse(w, http.StatusInternalServerError, "Database error")
		return
	}
	if user == nil {
		h.errorResponse(w, http.StatusUnauthorized, "User not found")
		return
	}

	h.jsonResponse(w, http.StatusOK, map[string]interface{}{
		"user":    user,
		"session": session,
	})
}
