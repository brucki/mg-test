defmodule ApiWeb.Router do
  use ApiWeb, :router

  # CORS pipeline
  pipeline :cors do
    plug(:accepts, ["json"])
    plug(:fetch_session)
    plug(ApiWeb.Plugs.CorsHeaders)
  end

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {ApiWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  pipeline :authenticated_api do
    plug(:accepts, ["json"])
    plug(ApiWeb.Plugs.ApiAuth)
  end

  # Browser routes
  scope "/", ApiWeb do
    pipe_through(:browser)
    get("/", PageController, :home)
  end

  # Health check endpoints (no CORS needed for internal use)
  scope "/", ApiWeb do
    pipe_through(:api)
    get("/health", HealthController, :check)
    get("/health/db", HealthController, :check_db)
  end

  # API routes with CORS enabled - use only one set of routes for users
  scope "/", ApiWeb do
    pipe_through([:cors])

    # Handle OPTIONS preflight requests for all /api/* routes
    options("/*path", ApiController, :options)

    # Public API endpoints
    resources "/users", UserController, except: [:new, :edit] do
      options("/:id", ApiController, :options)
    end

    # Authenticated API endpoints
    pipe_through(:authenticated_api)
    post("/import", ImportController, :import)
  end

  # Development routes
  if Application.compile_env(:api, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through(:browser)
      live_dashboard("/dashboard", metrics: ApiWeb.Telemetry)
      forward("/mailbox", Plug.Swoosh.MailboxPreview)
    end
  end
end
