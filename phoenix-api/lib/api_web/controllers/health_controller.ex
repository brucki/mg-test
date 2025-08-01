defmodule ApiWeb.HealthController do
  use ApiWeb, :controller

  def check(conn, _params) do
    # Basic health check that always returns 200 when the app is running
    json(conn, %{status: "ok", timestamp: DateTime.utc_now()})
  end

  def check_db(conn, _params) do
    # Check database connectivity
    case Ecto.Adapters.SQL.query(Api.Repo, "SELECT 1") do
      {:ok, _result} ->
        json(conn, %{status: "ok", database: "connected", timestamp: DateTime.utc_now()})
      {:error, error} ->
        conn
        |> put_status(:service_unavailable)
        |> json(%{status: "error", database: "disconnected", error: inspect(error)})
    end
  end
end
