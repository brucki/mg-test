defmodule ApiWeb.ImportController do
  use ApiWeb, :controller

  require Logger
  alias Api.DataImport

  @moduledoc """
  Controller for handling Polish data import operations.

  Provides REST endpoint for triggering the import of Polish demographic data
  and generation of random users. Includes concurrent import prevention and
  comprehensive error handling.
  """

  # GenServer for managing import state and preventing concurrent imports
  defmodule ImportState do
    use GenServer

    @moduledoc """
    GenServer for managing import state to prevent concurrent operations.
    """

    def start_link(_opts) do
      GenServer.start_link(__MODULE__, %{importing: false}, name: __MODULE__)
    end

    def init(state) do
      {:ok, state}
    end

    def is_importing? do
      GenServer.call(__MODULE__, :is_importing)
    end

    def start_import do
      GenServer.call(__MODULE__, :start_import)
    end

    def finish_import do
      GenServer.cast(__MODULE__, :finish_import)
    end

    # Test helper function
    def reset_state do
      GenServer.call(__MODULE__, :reset_state)
    end

    def handle_call(:is_importing, _from, state) do
      {:reply, state.importing, state}
    end

    def handle_call(:start_import, _from, %{importing: false} = state) do
      {:reply, :ok, %{state | importing: true}}
    end

    def handle_call(:start_import, _from, %{importing: true} = state) do
      {:reply, :already_importing, state}
    end

    def handle_call(:reset_state, _from, _state) do
      {:reply, :ok, %{importing: false}}
    end

    def handle_cast(:finish_import, state) do
      {:noreply, %{state | importing: false}}
    end
  end

  @doc """
  POST /import endpoint handler.

  Triggers the Polish data import process with concurrent import prevention.
  Returns JSON response with import results or error details.

  ## Request
  - Method: POST
  - Path: /import
  - Content-Type: application/json
  - Body: {} (empty JSON object)

  ## Response
  Success (HTTP 200):
  ```json
  {
    "success": true,
    "message": "Successfully imported Polish users",
    "data": {
      "users_imported": 100,
      "import_duration_ms": 1234
    }
  }
  ```

  Error responses:
  - HTTP 409: Import already in progress
  - HTTP 422: Import process failed
  - HTTP 500: Internal server error
  """
  def import(conn, params) do
    request_id = generate_request_id()
    client_ip = get_client_ip(conn)
    user_agent = get_req_header(conn, "user-agent") |> List.first()

    Logger.info("Import request received", %{
      request_id: request_id,
      client_ip: client_ip,
      user_agent: user_agent,
      request_params: params,
      request_method: conn.method,
      request_path: conn.request_path,
      timestamp: DateTime.utc_now()
    })

    start_time = System.monotonic_time(:millisecond)

    # Validate request format
    case validate_import_request(conn) do
      :ok ->
        Logger.debug("Request validation passed", %{request_id: request_id})
        handle_import_request(conn, start_time, request_id)

      {:error, reason} ->
        end_time = System.monotonic_time(:millisecond)
        duration = end_time - start_time

        Logger.warning("Invalid import request rejected", %{
          request_id: request_id,
          validation_error: reason,
          client_ip: client_ip,
          request_duration_ms: duration
        })

        render_error_response(conn, 400, "bad_request", "Invalid request format")
    end
  end

  # Private functions

  defp validate_import_request(conn) do
    # Ensure the request accepts JSON
    case get_req_header(conn, "accept") do
      [] ->
        # No accept header is fine
        :ok

      headers ->
        if Enum.any?(headers, &String.contains?(&1, "application/json")) do
          :ok
        else
          {:error, :invalid_accept_header}
        end
    end
  end

  defp handle_import_request(conn, start_time, request_id) do
    # Check if import is already in progress
    case ImportState.start_import() do
      :ok ->
        Logger.info("Starting new import process", %{
          request_id: request_id,
          import_state: "acquired_lock"
        })

        execute_import(conn, start_time, request_id)

      :already_importing ->
        end_time = System.monotonic_time(:millisecond)
        duration = end_time - start_time

        Logger.warning("Import request rejected - concurrent import prevention", %{
          request_id: request_id,
          rejection_reason: "import_already_in_progress",
          request_duration_ms: duration,
          client_ip: get_client_ip(conn)
        })

        render_error_response(conn, 409, "import_in_progress", "Import is already in progress")
    end
  end

  defp execute_import(conn, start_time, request_id) do
    try do
      Logger.info("Executing import process", %{
        request_id: request_id,
        process_pid: inspect(self())
      })

      case DataImport.import_polish_users() do
        {:ok, count} ->
          end_time = System.monotonic_time(:millisecond)
          duration = end_time - start_time

          Logger.info("Import completed successfully", %{
            request_id: request_id,
            users_imported: count,
            total_duration_ms: duration,
            client_ip: get_client_ip(conn),
            completion_timestamp: DateTime.utc_now()
          })

          render_success_response(conn, %{
            users_imported: count,
            import_duration_ms: duration
          })

        {:error, reason} ->
          end_time = System.monotonic_time(:millisecond)
          duration = end_time - start_time

          Logger.error("Import process failed", %{
            request_id: request_id,
            error_reason: reason,
            total_duration_ms: duration,
            client_ip: get_client_ip(conn),
            failure_timestamp: DateTime.utc_now()
          })

          render_import_error_response(conn, reason)
      end
    rescue
      error ->
        end_time = System.monotonic_time(:millisecond)
        duration = end_time - start_time

        Logger.error("Unexpected exception during import execution", %{
          request_id: request_id,
          exception: error,
          stacktrace: __STACKTRACE__,
          duration_ms: duration,
          client_ip: get_client_ip(conn)
        })

        render_error_response(conn, 500, "internal_error", "An unexpected error occurred")
    after
      # Always finish the import state, even if an exception occurs
      Logger.debug("Releasing import lock", %{request_id: request_id})
      ImportState.finish_import()
    end
  end

  defp render_success_response(conn, data) do
    conn
    |> put_status(200)
    |> json(%{
      success: true,
      message: "Successfully imported Polish users",
      data: data
    })
  end

  defp render_import_error_response(conn, reason) do
    {status_code, error_code, message} = map_import_error(reason)
    render_error_response(conn, status_code, error_code, message)
  end

  defp render_error_response(conn, status_code, error_code, message) do
    conn
    |> put_status(status_code)
    |> json(%{
      success: false,
      error: %{
        code: error_code,
        message: message
      }
    })
  end

  defp map_import_error(reason) do
    case reason do
      {:api_connection_failed, message} ->
        {422, "api_connection_failed", message}

      {:api_http_error, message} ->
        {422, "api_http_error", message}

      {:api_response_invalid, message} ->
        {422, "api_response_invalid", message}

      {:api_data_invalid, message} ->
        {422, "api_data_invalid", message}

      {:user_generation_failed, message} ->
        {422, "user_generation_failed", message}

      {:validation_failed, message} ->
        {422, "validation_failed", message}

      {:partial_database_failure, message} ->
        {422, "partial_database_failure", message}

      {:database_error, message} ->
        {500, "database_error", message}

      {:unknown_import_error, _details} ->
        {500, "unknown_error", "An unknown error occurred during import"}

      _other ->
        {500, "internal_error", "An internal error occurred"}
    end
  end

  defp get_client_ip(conn) do
    case get_req_header(conn, "x-forwarded-for") do
      [ip | _] ->
        ip

      [] ->
        case conn.remote_ip do
          {a, b, c, d} -> "#{a}.#{b}.#{c}.#{d}"
          other -> inspect(other)
        end
    end
  end

  defp generate_request_id do
    :crypto.strong_rand_bytes(6) |> Base.encode16(case: :lower)
  end
end
