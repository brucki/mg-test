import Config

# Configures Swoosh API Client
config :swoosh, api_client: Swoosh.ApiClient.Finch, finch_name: Api.Finch

# Disable Swoosh Local Memory Storage
config :swoosh, local: false

# Do not print debug messages in production
config :logger, level: :info

# Production-specific Data Import settings
config :api, Api.DataImport,
  # Longer timeout for production
  request_timeout: 60_000,
  max_retries: 5

# API authentication for import endpoints
# Set via environment variable: IMPORT_API_TOKEN
# config :api, ApiWeb.Plugs.ApiAuth,
#   import_api_token: System.get_env("IMPORT_API_TOKEN")

# Runtime production configuration, including reading
# of environment variables, is done on config/runtime.exs.
