defmodule ApiWeb.ApiController do
  @moduledoc """
  Controller for handling API-wide endpoints and CORS preflight requests.
  """
  use ApiWeb, :controller

  @doc """
  Handle CORS preflight requests.
  This endpoint is used by the browser to check if the CORS request is allowed.
  The actual CORS headers are set in the CorsHeaders plug.
  """
  def options(conn, _params) do
    # The response will be handled by the CorsHeaders plug
    send_resp(conn, :no_content, "")
  end
end
