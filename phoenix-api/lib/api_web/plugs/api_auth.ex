defmodule ApiWeb.Plugs.ApiAuth do
  @moduledoc """
  Optional API token authentication plug for import endpoints.

  This plug provides optional API token authentication. If a token is configured
  in the application environment, requests must include a valid Authorization header.
  If no token is configured, all requests are allowed through.

  ## Configuration

  Set the API token in your config:

      config :api, ApiWeb.Plugs.ApiAuth,
        import_api_token: "your-secret-token"

  ## Usage

  Add to your router pipeline:

      pipeline :authenticated_api do
        plug :accepts, ["json"]
        plug ApiWeb.Plugs.ApiAuth
      end

  ## Request Format

  Include the token in the Authorization header:

      Authorization: Bearer your-secret-token

  ## Responses

  - If authentication is required but missing: HTTP 401
  - If authentication is required but invalid: HTTP 401
  - If authentication is not required: Request continues
  """

  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  require Logger

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_configured_token() do
      nil ->
        # No token configured, allow all requests
        conn

      configured_token ->
        # Token is configured, require authentication
        authenticate_request(conn, configured_token)
    end
  end

  defp get_configured_token do
    Application.get_env(:api, __MODULE__, [])
    |> Keyword.get(:import_api_token)
  end

  defp authenticate_request(conn, configured_token) do
    case get_auth_token(conn) do
      {:ok, token} ->
        validate_token(conn, token, configured_token)

      {:error, reason} ->
        Logger.warning("API authentication failed: #{inspect(reason)}")
        render_auth_error(conn, reason)
    end
  end

  defp get_auth_token(conn) do
    case get_req_header(conn, "authorization") do
      [] ->
        {:error, :missing_authorization_header}

      [auth_header | _] ->
        parse_auth_header(auth_header)
    end
  end

  defp parse_auth_header("Bearer " <> token) when byte_size(token) > 0 do
    {:ok, String.trim(token)}
  end

  defp parse_auth_header(_invalid_header) do
    {:error, :invalid_authorization_format}
  end

  defp validate_token(conn, provided_token, configured_token) do
    if secure_compare(provided_token, configured_token) do
      Logger.info("API request authenticated successfully")
      conn
    else
      Logger.warning("API authentication failed: invalid token")
      render_auth_error(conn, :invalid_token)
    end
  end

  defp secure_compare(a, b) when byte_size(a) == byte_size(b) do
    # Use constant-time comparison to prevent timing attacks
    :crypto.hash_equals(a, b)
  end

  defp secure_compare(_a, _b), do: false

  defp render_auth_error(conn, reason) do
    {message, details} = format_auth_error(reason)

    conn
    |> put_status(401)
    |> json(%{
      success: false,
      error: %{
        code: "authentication_required",
        message: message,
        details: details
      }
    })
    |> halt()
  end

  defp format_auth_error(reason) do
    case reason do
      :missing_authorization_header ->
        {"Authentication required", "Missing Authorization header"}

      :invalid_authorization_format ->
        {"Authentication required", "Authorization header must be in format: Bearer <token>"}

      :invalid_token ->
        {"Authentication failed", "Invalid API token"}

      _other ->
        {"Authentication failed", "Authentication error"}
    end
  end
end
