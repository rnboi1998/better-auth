# BetterAuth Elixir

A feature-equivalent Elixir implementation of the [Better Auth](https://better-auth.com) library, designed for the Phoenix framework.

## Installation

1.  Add `better_auth` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [
        {:better_auth, path: "path/to/better-auth-elixir"} # or git repo
      ]
    end
    ```

2.  Configure your repository in `config/config.exs`:

    ```elixir
    config :better_auth, repo: MyApp.Repo
    ```

3.  Generate and run the migration:

    ```bash
    mix better_auth.gen.migration MyApp.Repo
    mix ecto.migrate
    ```

4.  Add the routes to your router (`lib/my_app_web/router.ex`):

    ```elixir
    scope "/api/auth", MyAppWeb do
      pipe_through :api

      require BetterAuth.Web.Router
      BetterAuth.Web.Router.better_auth_routes()
    end
    ```

## Usage

### Authentication

BetterAuth provides endpoints for email/password authentication:

-   `POST /api/auth/sign-up/email`: Sign up with email, password, and name.
-   `POST /api/auth/sign-in/email`: Sign in with email and password.
-   `POST /api/auth/sign-out`: Sign out.
-   `GET /api/auth/session`: Get the current session.

### Verification Plug

To protect routes, use `BetterAuth.Web.Plug`:

```elixir
pipeline :authenticated do
  plug BetterAuth.Web.Plug
end

scope "/admin", MyAppWeb do
  pipe_through [:browser, :authenticated]

  get "/dashboard", AdminController, :index
end
```

In your controller, you can access the current user via `conn.assigns.current_user`.

## Configuration

BetterAuth uses Argon2 for password hashing. Ensure you have the necessary system dependencies installed if required by `argon2_elixir`.

## Contributing

Contributions are welcome!
