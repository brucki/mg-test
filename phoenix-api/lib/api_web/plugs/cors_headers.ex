defmodule ApiWeb.Plugs.CorsHeaders do
  @moduledoc """
  Plug to handle CORS headers for API requests.
  """
  import Plug.Conn

  @allowed_origins [
    "http://localhost:8000",
    "http://localhost:4000",
    "http://127.0.0.1:8000",
    "http://phoenix:4000"
  ]
  
  @allowed_methods ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS", "HEAD"]
  @allowed_headers ["Content-Type", "Authorization", "Accept", "Origin", "X-Requested-With", "X-CSRF-Token"]
  @exposed_headers ["Authorization", "Content-Type", "X-Request-Id", "X-Request-Duration"]

  def init(opts), do: opts

  def call(conn, _opts) do
    origin = get_req_header(conn, "origin") |> List.first()
    
    # Always set CORS headers, even for non-preflight requests
    conn = conn
    |> maybe_add_cors_headers(origin)
    
    # Handle preflight requests
    if conn.method == "OPTIONS" do
      handle_preflight(conn, origin)
    else
      conn
    end
  end

  defp maybe_add_cors_headers(conn, origin) when is_binary(origin) do
    if origin in @allowed_origins do
      conn
      |> put_resp_header("access-control-allow-origin", origin)
      |> put_resp_header("access-control-allow-methods", Enum.join(@allowed_methods, ", "))
      |> put_resp_header("access-control-allow-headers", Enum.join(@allowed_headers, ", "))
      |> put_resp_header("access-control-expose-headers", Enum.join(@exposed_headers, ", "))
      |> put_resp_header("access-control-allow-credentials", "true")
      |> put_resp_header("vary", "Origin")
    else
      conn
      |> put_resp_header("access-control-allow-origin", "*")
      |> put_resp_header("access-control-allow-methods", Enum.join(@allowed_methods, ", "))
      |> put_resp_header("access-control-allow-headers", Enum.join(@allowed_headers, ", "))
    end
  end
  
  defp maybe_add_cors_headers(conn, _), do: conn

  defp handle_preflight(conn, origin) when is_binary(origin) do
    conn = conn
    |> put_resp_header("access-control-allow-origin", origin)
    |> put_resp_header("access-control-allow-methods", Enum.join(@allowed_methods, ", "))
    |> put_resp_header("access-control-allow-headers", Enum.join(@allowed_headers, ", "))
    |> put_resp_header("access-control-max-age", "3600")
    |> put_resp_header("access-control-allow-credentials", "true")
    
    if origin in @allowed_origins do
      conn
      |> send_resp(:no_content, "")
      |> halt()
    else
      conn
      |> send_resp(:forbidden, "")
      |> halt()
    end
  end
  
  defp handle_preflight(conn, _) do
    conn
    |> send_resp(:forbidden, "")
    |> halt()
  end
end
