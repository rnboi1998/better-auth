package api

func (h *Handler) registerRoutes() {
	h.Routes["/sign-up/email"] = h.handleSignUpEmail
	h.Routes["/sign-in/email"] = h.handleSignInEmail
	h.Routes["/get-session"] = h.handleGetSession

	// Register plugins
	for _, plugin := range h.Options.Plugins {
		for path, handler := range plugin.Endpoints {
			h.Routes[path] = handler
		}
	}
}
