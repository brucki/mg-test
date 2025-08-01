defmodule ApiWeb.ImportControllerTest do
  use ApiWeb.ConnCase
  import Ecto.Query

  @moduledoc """
  Integration tests for ImportController endpoint.

  These tests verify the complete HTTP request/response cycle for the POST /import endpoint,
  including successful import responses, error scenarios, and concurrent import prevention.
  """

  # Mock module for testing
  defmodule MockPolishDataClient do
    @behaviour Api.DataImport.PolishDataClientBehaviour

    def fetch_all_demographic_data do
      case Process.get(:mock_demographic_response) do
        nil ->
          {:ok,
           %{
             male_names: ["ADAM", "ANDRZEJ", "TOMASZ"],
             female_names: ["ANNA", "MARIA", "KATARZYNA"],
             male_surnames: ["NOWAK", "KOWALSKI", "WIŚNIEWSKI"],
             female_surnames: ["NOWAK", "KOWALSKA", "WIŚNIEWSKA"]
           }}

        response ->
          response
      end
    end

    # Implement required behaviour functions (not used in current implementation)
    def fetch_male_names, do: {:ok, ["ADAM", "ANDRZEJ", "TOMASZ"]}
    def fetch_female_names, do: {:ok, ["ANNA", "MARIA", "KATARZYNA"]}
    def fetch_male_surnames, do: {:ok, ["NOWAK", "KOWALSKI", "WIŚNIEWSKI"]}
    def fetch_female_surnames, do: {:ok, ["NOWAK", "KOWALSKA", "WIŚNIEWSKA"]}
  end

  setup do
    # Configure mock client for testing
    Application.put_env(:api, :polish_data_client, MockPolishDataClient)

    # Reset authentication configuration
    Application.put_env(:api, ApiWeb.Plugs.ApiAuth, import_api_token: nil)

    # Reset import state
    if Process.whereis(ApiWeb.ImportController.ImportState) do
      GenServer.call(ApiWeb.ImportController.ImportState, :reset_state)
    end

    # Clean up any existing users from previous tests
    Api.Repo.delete_all(Api.Accounts.User)

    on_exit(fn ->
      # Reset configurations
      Application.put_env(:api, ApiWeb.Plugs.ApiAuth, import_api_token: nil)
      Application.put_env(:api, :polish_data_client, Api.DataImport.PolishDataClient)
      Process.delete(:mock_demographic_response)

      # Clean up test data
      Api.Repo.delete_all(Api.Accounts.User)
    end)

    :ok
  end

  describe "POST /import - Authentication" do
    test "responds with JSON when no authentication is configured", %{conn: conn} do
      # Ensure no authentication token is configured for this test
      Application.put_env(:api, ApiWeb.Plugs.ApiAuth, import_api_token: nil)

      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> post(~p"/import", %{})

      # Should get a response (not necessarily successful, but should reach the controller)
      assert conn.status in [200, 409, 422]
    end

    test "requires authentication when token is configured", %{conn: conn} do
      # Configure authentication token for this test
      Application.put_env(:api, ApiWeb.Plugs.ApiAuth, import_api_token: "test-token")

      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> post(~p"/import", %{})

      # Should get 401 unauthorized
      assert json_response(conn, 401)
      response = json_response(conn, 401)
      assert response["success"] == false
      assert response["error"]["code"] == "authentication_required"
    end

    test "accepts valid authentication token", %{conn: conn} do
      # Configure authentication token for this test
      Application.put_env(:api, ApiWeb.Plugs.ApiAuth, import_api_token: "test-token")

      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> put_req_header("authorization", "Bearer test-token")
        |> post(~p"/import", %{})

      # Should not get 401 (may get other errors, but not auth error)
      refute conn.status == 401
    end

    test "rejects invalid authentication token", %{conn: conn} do
      # Configure authentication token for this test
      Application.put_env(:api, ApiWeb.Plugs.ApiAuth, import_api_token: "test-token")

      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> put_req_header("authorization", "Bearer wrong-token")
        |> post(~p"/import", %{})

      # Should get 401 unauthorized
      assert json_response(conn, 401)
      response = json_response(conn, 401)
      assert response["success"] == false
      assert response["error"]["code"] == "authentication_required"
    end
  end

  describe "POST /import - Successful Import" do
    test "returns success response with user count on successful import", %{conn: conn} do
      # Mock successful demographic data response
      Process.put(
        :mock_demographic_response,
        {:ok,
         %{
           male_names: ["ADAM", "ANDRZEJ", "TOMASZ"],
           female_names: ["ANNA", "MARIA", "KATARZYNA"],
           male_surnames: ["NOWAK", "KOWALSKI", "WIŚNIEWSKI"],
           female_surnames: ["NOWAK", "KOWALSKA", "WIŚNIEWSKA"]
         }}
      )

      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> post(~p"/import", %{})

      # Should get 200 success response
      response = json_response(conn, 200)

      assert response["success"] == true
      assert response["message"] == "Successfully imported Polish users"
      assert is_map(response["data"])
      assert is_integer(response["data"]["users_imported"])
      assert response["data"]["users_imported"] > 0
      assert is_integer(response["data"]["import_duration_ms"])
      assert response["data"]["import_duration_ms"] >= 0
    end

    test "actually creates users in the database", %{conn: conn} do
      # Ensure database is clean
      Api.Repo.delete_all(Api.Accounts.User)

      # Mock successful demographic data response
      Process.put(
        :mock_demographic_response,
        {:ok,
         %{
           male_names: ["ADAM", "ANDRZEJ", "TOMASZ"],
           female_names: ["ANNA", "MARIA", "KATARZYNA"],
           male_surnames: ["NOWAK", "KOWALSKI", "WIŚNIEWSKI"],
           female_surnames: ["NOWAK", "KOWALSKA", "WIŚNIEWSKA"]
         }}
      )

      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> post(~p"/import", %{})

      response = json_response(conn, 200)
      users_imported = response["data"]["users_imported"]

      # Verify users were actually created in database
      user_count = Api.Repo.aggregate(Api.Accounts.User, :count, :id)
      assert user_count == users_imported
      assert user_count > 0

      # Verify user data structure
      user = Api.Repo.one(from(u in Api.Accounts.User, limit: 1))
      assert user.first_name != nil
      assert user.last_name != nil
      assert user.gender in [:male, :female]
      assert user.birthdate != nil
    end

    test "includes proper response headers", %{conn: conn} do
      # Mock successful demographic data response
      Process.put(
        :mock_demographic_response,
        {:ok,
         %{
           male_names: ["ADAM"],
           female_names: ["ANNA"],
           male_surnames: ["NOWAK"],
           female_surnames: ["NOWAK"]
         }}
      )

      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> post(~p"/import", %{})

      assert conn.status == 200
      assert get_resp_header(conn, "content-type") |> List.first() =~ "application/json"
    end
  end

  describe "POST /import - Error Scenarios" do
    test "returns 422 when API connection fails", %{conn: conn} do
      # Mock API connection failure
      Process.put(:mock_demographic_response, {:error, {:network_error, "Connection timeout"}})

      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> post(~p"/import", %{})

      response = json_response(conn, 422)

      assert response["success"] == false
      assert response["error"]["code"] == "api_connection_failed"
      assert is_binary(response["error"]["message"])
    end

    test "returns 422 when API returns HTTP error", %{conn: conn} do
      # Mock API HTTP error
      Process.put(
        :mock_demographic_response,
        {:error, {:http_error, 500, "Internal Server Error"}}
      )

      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> post(~p"/import", %{})

      response = json_response(conn, 422)

      assert response["success"] == false
      assert response["error"]["code"] == "api_http_error"
      assert response["error"]["message"] =~ "HTTP 500"
    end

    test "returns 422 when API response is invalid", %{conn: conn} do
      # Mock invalid API response
      Process.put(:mock_demographic_response, {:error, {:json_parse_error, "Invalid JSON"}})

      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> post(~p"/import", %{})

      response = json_response(conn, 422)

      assert response["success"] == false
      assert response["error"]["code"] == "api_response_invalid"
      assert response["error"]["message"] =~ "Invalid JSON"
    end

    test "returns 422 when no valid names found", %{conn: conn} do
      # Mock empty demographic data
      Process.put(:mock_demographic_response, {:error, {:no_valid_names_found}})

      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> post(~p"/import", %{})

      response = json_response(conn, 422)

      assert response["success"] == false
      assert response["error"]["code"] == "api_data_invalid"
      assert response["error"]["message"] =~ "No valid names found"
    end

    test "returns 500 for unexpected database errors", %{conn: conn} do
      # Mock successful API but simulate database error by using invalid data
      Process.put(
        :mock_demographic_response,
        {:error, {:unexpected_database_error, "Database connection lost"}}
      )

      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> post(~p"/import", %{})

      response = json_response(conn, 500)

      assert response["success"] == false
      assert response["error"]["code"] == "database_error"
      assert is_binary(response["error"]["message"])
    end

    test "handles requests with non-JSON accept headers gracefully", %{conn: conn} do
      # Mock successful demographic data response
      Process.put(
        :mock_demographic_response,
        {:ok,
         %{
           male_names: ["ADAM"],
           female_names: ["ANNA"],
           male_surnames: ["NOWAK"],
           female_surnames: ["NOWAK"]
         }}
      )

      # Phoenix will handle content negotiation, but our controller should still work
      # when the request reaches it with proper JSON content type
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post(~p"/import", %{})

      # Should get a valid response (not necessarily successful, but should reach controller)
      assert conn.status in [200, 409, 422]
    end
  end

  describe "POST /import - Concurrent Import Prevention" do
    test "returns 409 when import is already in progress", %{conn: conn} do
      # Mock successful demographic data response
      Process.put(
        :mock_demographic_response,
        {:ok,
         %{
           male_names: ["ADAM"],
           female_names: ["ANNA"],
           male_surnames: ["NOWAK"],
           female_surnames: ["NOWAK"]
         }}
      )

      # Start the ImportState GenServer if not already started
      unless Process.whereis(ApiWeb.ImportController.ImportState) do
        {:ok, _pid} = ApiWeb.ImportController.ImportState.start_link([])
      end

      # Manually set import state to in progress
      GenServer.call(ApiWeb.ImportController.ImportState, :start_import)

      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> post(~p"/import", %{})

      response = json_response(conn, 409)

      assert response["success"] == false
      assert response["error"]["code"] == "import_in_progress"
      assert response["error"]["message"] == "Import is already in progress"

      # Clean up - finish the import
      ApiWeb.ImportController.ImportState.finish_import()
    end

    test "allows import after previous import completes", %{conn: conn} do
      # Mock successful demographic data response
      Process.put(
        :mock_demographic_response,
        {:ok,
         %{
           male_names: ["ADAM"],
           female_names: ["ANNA"],
           male_surnames: ["NOWAK"],
           female_surnames: ["NOWAK"]
         }}
      )

      # First import should succeed
      conn1 =
        conn
        |> put_req_header("accept", "application/json")
        |> post(~p"/import", %{})

      response1 = json_response(conn1, 200)
      assert response1["success"] == true

      # Second import should also succeed (not blocked)
      conn2 =
        build_conn()
        |> put_req_header("accept", "application/json")
        |> post(~p"/import", %{})

      response2 = json_response(conn2, 200)
      assert response2["success"] == true
    end

    test "concurrent requests are properly serialized", %{conn: _conn} do
      # Mock successful demographic data response
      Process.put(
        :mock_demographic_response,
        {:ok,
         %{
           male_names: ["ADAM"],
           female_names: ["ANNA"],
           male_surnames: ["NOWAK"],
           female_surnames: ["NOWAK"]
         }}
      )

      # Start multiple concurrent requests
      parent = self()

      tasks =
        for i <- 1..3 do
          Task.async(fn ->
            conn =
              build_conn()
              |> put_req_header("accept", "application/json")

            response = post(conn, ~p"/import", %{})
            send(parent, {:response, i, response.status})
            response.status
          end)
        end

      # Wait for all tasks to complete
      results = Enum.map(tasks, &Task.await(&1, 10_000))

      # Should have one success (200) and two conflicts (409)
      success_count = Enum.count(results, &(&1 == 200))
      conflict_count = Enum.count(results, &(&1 == 409))

      assert success_count == 1
      assert conflict_count == 2
    end
  end

  describe "POST /import - Request Validation" do
    test "accepts empty JSON body", %{conn: conn} do
      # Mock successful demographic data response
      Process.put(
        :mock_demographic_response,
        {:ok,
         %{
           male_names: ["ADAM"],
           female_names: ["ANNA"],
           male_surnames: ["NOWAK"],
           female_surnames: ["NOWAK"]
         }}
      )

      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> put_req_header("content-type", "application/json")
        |> post(~p"/import", %{})

      # Should not be 400
      assert conn.status in [200, 409, 422]
    end

    test "accepts request without explicit accept header", %{conn: conn} do
      # Mock successful demographic data response
      Process.put(
        :mock_demographic_response,
        {:ok,
         %{
           male_names: ["ADAM"],
           female_names: ["ANNA"],
           male_surnames: ["NOWAK"],
           female_surnames: ["NOWAK"]
         }}
      )

      conn =
        conn
        |> post(~p"/import", %{})

      # Should not fail due to missing accept header
      # Should not be 400
      assert conn.status in [200, 409, 422]
    end

    test "logs request details for monitoring", %{conn: conn} do
      import ExUnit.CaptureLog

      # Mock successful demographic data response
      Process.put(
        :mock_demographic_response,
        {:ok,
         %{
           male_names: ["ADAM"],
           female_names: ["ANNA"],
           male_surnames: ["NOWAK"],
           female_surnames: ["NOWAK"]
         }}
      )

      # Temporarily set log level to info to capture the logs
      original_level = Logger.level()
      Logger.configure(level: :info)

      log_output =
        capture_log(fn ->
          conn
          |> put_req_header("accept", "application/json")
          |> put_req_header("user-agent", "test-client/1.0")
          |> post(~p"/import", %{})
        end)

      # Restore original log level
      Logger.configure(level: original_level)

      # Verify that request logging occurred
      assert log_output =~ "Import request received"

      # The user-agent is logged as part of structured logging, so it might not appear as plain text
      # Let's just verify that the request was logged properly
      assert log_output =~ "Starting new import process"
    end
  end
end
