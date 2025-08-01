defmodule Api.DataImport.PolishDataClientTest do
  use ExUnit.Case, async: true
  import Mox
  alias Api.DataImport.PolishDataClient

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  setup do
    # Set the HTTP client to use our mock for tests
    Application.put_env(:api, :http_client, HTTPoisonMock)

    on_exit(fn ->
      # Reset to default after test
      Application.delete_env(:api, :http_client)
    end)

    :ok
  end

  describe "parse_response/1" do
    test "successfully parses valid API response" do
      response_body = """
      {
        "data": [
          {"attributes": {"col1": {"repr": "ANNA"}, "col2": {"repr": "12345"}}},
          {"attributes": {"col1": {"repr": "MARIA"}, "col2": {"repr": "11000"}}},
          {"attributes": {"col1": {"repr": "KATARZYNA"}, "col2": {"repr": "9500"}}}
        ],
        "meta": {"count": 3, "page": 1}
      }
      """

      assert {:ok, names} = PolishDataClient.parse_response(response_body)
      assert length(names) == 3
      assert "ANNA" in names
      assert "MARIA" in names
      assert "KATARZYNA" in names
    end

    test "handles empty data array" do
      response_body = """
      {
        "data": [],
        "meta": {"count": 0, "page": 1}
      }
      """

      assert {:error, :no_valid_names_found} = PolishDataClient.parse_response(response_body)
    end

    test "handles invalid JSON" do
      response_body = "invalid json"

      assert {:error, {:json_parse_error, _reason}} =
               PolishDataClient.parse_response(response_body)
    end

    test "handles missing data field" do
      response_body = """
      {
        "meta": {"count": 0, "page": 1}
      }
      """

      assert {:error, {:invalid_response_structure, _response}} =
               PolishDataClient.parse_response(response_body)
    end

    test "filters out invalid names" do
      response_body = """
      {
        "data": [
          {"attributes": {"col1": {"repr": "ANNA"}, "col2": {"repr": "12345"}}},
          {"attributes": {"col1": {"repr": ""}, "col2": {"repr": "11000"}}},
          {"attributes": {"col1": {"repr": "MARIA123"}, "col2": {"repr": "9500"}}},
          {"attributes": {"col1": {"repr": "KATARZYNA"}, "col2": {"repr": "8000"}}}
        ],
        "meta": {"count": 4, "page": 1}
      }
      """

      assert {:ok, names} = PolishDataClient.parse_response(response_body)
      assert length(names) == 2
      assert "ANNA" in names
      assert "KATARZYNA" in names
      refute "" in names
      refute "MARIA123" in names
    end
  end

  describe "fetch_male_names/0" do
    test "successfully fetches male names from API" do
      successful_response = %HTTPoison.Response{
        status_code: 200,
        body: """
        {
          "data": [
            {"attributes": {"col1": {"repr": "ADAM"}, "col2": {"repr": "15000"}}},
            {"attributes": {"col1": {"repr": "ANDRZEJ"}, "col2": {"repr": "14000"}}},
            {"attributes": {"col1": {"repr": "PIOTR"}, "col2": {"repr": "13000"}}}
          ],
          "meta": {"count": 3, "page": 1}
        }
        """,
        headers: [{"content-type", "application/json"}]
      }

      HTTPoisonMock
      |> expect(:get, fn _url, _headers, _options ->
        {:ok, successful_response}
      end)

      assert {:ok, names} = PolishDataClient.fetch_male_names()
      assert length(names) == 3
      assert "ADAM" in names
      assert "ANDRZEJ" in names
      assert "PIOTR" in names
    end

    test "handles HTTP error responses" do
      error_response = %HTTPoison.Response{
        status_code: 500,
        body: "Internal Server Error",
        headers: [{"content-type", "text/plain"}]
      }

      HTTPoisonMock
      |> expect(:get, fn _url, _headers, _options ->
        {:ok, error_response}
      end)

      assert {:error, {:http_error, 500, "Internal Server Error"}} =
               PolishDataClient.fetch_male_names()
    end

    test "handles network errors with retry logic" do
      network_error = %HTTPoison.Error{reason: :timeout}

      HTTPoisonMock
      |> expect(:get, 3, fn _url, _headers, _options ->
        {:error, network_error}
      end)

      assert {:error, {:network_error, :timeout}} = PolishDataClient.fetch_male_names()
    end

    test "succeeds after retry on network error" do
      network_error = %HTTPoison.Error{reason: :timeout}

      successful_response = %HTTPoison.Response{
        status_code: 200,
        body: """
        {
          "data": [
            {"attributes": {"col1": {"repr": "ADAM"}, "col2": {"repr": "15000"}}}
          ],
          "meta": {"count": 1, "page": 1}
        }
        """,
        headers: [{"content-type", "application/json"}]
      }

      HTTPoisonMock
      |> expect(:get, fn _url, _headers, _options ->
        {:error, network_error}
      end)
      |> expect(:get, fn _url, _headers, _options ->
        {:ok, successful_response}
      end)

      assert {:ok, names} = PolishDataClient.fetch_male_names()
      assert length(names) == 1
      assert "ADAM" in names
    end
  end

  describe "fetch_female_names/0" do
    test "successfully fetches female names from API" do
      successful_response = %HTTPoison.Response{
        status_code: 200,
        body: """
        {
          "data": [
            {"attributes": {"col1": {"repr": "ANNA"}, "col2": {"repr": "16000"}}},
            {"attributes": {"col1": {"repr": "MARIA"}, "col2": {"repr": "15000"}}},
            {"attributes": {"col1": {"repr": "KATARZYNA"}, "col2": {"repr": "14000"}}}
          ],
          "meta": {"count": 3, "page": 1}
        }
        """,
        headers: [{"content-type", "application/json"}]
      }

      HTTPoisonMock
      |> expect(:get, fn _url, _headers, _options ->
        {:ok, successful_response}
      end)

      assert {:ok, names} = PolishDataClient.fetch_female_names()
      assert length(names) == 3
      assert "ANNA" in names
      assert "MARIA" in names
      assert "KATARZYNA" in names
    end

    test "handles invalid JSON response" do
      invalid_json_response = %HTTPoison.Response{
        status_code: 200,
        body: "invalid json response",
        headers: [{"content-type", "application/json"}]
      }

      HTTPoisonMock
      |> expect(:get, fn _url, _headers, _options ->
        {:ok, invalid_json_response}
      end)

      assert {:error, {:json_parse_error, _reason}} = PolishDataClient.fetch_female_names()
    end
  end

  describe "fetch_male_surnames/0" do
    test "successfully fetches male surnames from API" do
      successful_response = %HTTPoison.Response{
        status_code: 200,
        body: """
        {
          "data": [
            {"attributes": {"col1": {"repr": "NOWAK"}, "col2": {"repr": "20000"}}},
            {"attributes": {"col1": {"repr": "KOWALSKI"}, "col2": {"repr": "19000"}}},
            {"attributes": {"col1": {"repr": "WIŚNIEWSKI"}, "col2": {"repr": "18000"}}}
          ],
          "meta": {"count": 3, "page": 1}
        }
        """,
        headers: [{"content-type", "application/json"}]
      }

      HTTPoisonMock
      |> expect(:get, fn _url, _headers, _options ->
        {:ok, successful_response}
      end)

      assert {:ok, surnames} = PolishDataClient.fetch_male_surnames()
      assert length(surnames) == 3
      assert "NOWAK" in surnames
      assert "KOWALSKI" in surnames
      assert "WIŚNIEWSKI" in surnames
    end
  end

  describe "fetch_female_surnames/0" do
    test "successfully fetches female surnames from API" do
      successful_response = %HTTPoison.Response{
        status_code: 200,
        body: """
        {
          "data": [
            {"attributes": {"col1": {"repr": "NOWAK"}, "col2": {"repr": "20000"}}},
            {"attributes": {"col1": {"repr": "KOWALSKA"}, "col2": {"repr": "19000"}}},
            {"attributes": {"col1": {"repr": "WIŚNIEWSKA"}, "col2": {"repr": "18000"}}}
          ],
          "meta": {"count": 3, "page": 1}
        }
        """,
        headers: [{"content-type", "application/json"}]
      }

      HTTPoisonMock
      |> expect(:get, fn _url, _headers, _options ->
        {:ok, successful_response}
      end)

      assert {:ok, surnames} = PolishDataClient.fetch_female_surnames()
      assert length(surnames) == 3
      assert "NOWAK" in surnames
      assert "KOWALSKA" in surnames
      assert "WIŚNIEWSKA" in surnames
    end
  end

  describe "fetch_all_demographic_data/0" do
    test "successfully fetches all demographic data" do
      male_names_response = %HTTPoison.Response{
        status_code: 200,
        body: """
        {
          "data": [
            {"attributes": {"col1": {"repr": "ADAM"}, "col2": {"repr": "15000"}}}
          ],
          "meta": {"count": 1, "page": 1}
        }
        """,
        headers: [{"content-type", "application/json"}]
      }

      female_names_response = %HTTPoison.Response{
        status_code: 200,
        body: """
        {
          "data": [
            {"attributes": {"col1": {"repr": "ANNA"}, "col2": {"repr": "16000"}}}
          ],
          "meta": {"count": 1, "page": 1}
        }
        """,
        headers: [{"content-type", "application/json"}]
      }

      male_surnames_response = %HTTPoison.Response{
        status_code: 200,
        body: """
        {
          "data": [
            {"attributes": {"col1": {"repr": "NOWAK"}, "col2": {"repr": "20000"}}}
          ],
          "meta": {"count": 1, "page": 1}
        }
        """,
        headers: [{"content-type", "application/json"}]
      }

      female_surnames_response = %HTTPoison.Response{
        status_code: 200,
        body: """
        {
          "data": [
            {"attributes": {"col1": {"repr": "KOWALSKA"}, "col2": {"repr": "19000"}}}
          ],
          "meta": {"count": 1, "page": 1}
        }
        """,
        headers: [{"content-type", "application/json"}]
      }

      # Mock the 4 API calls in order: male_names, female_names, male_surnames, female_surnames
      HTTPoisonMock
      |> expect(:get, fn _url, _headers, _options ->
        {:ok, male_names_response}
      end)
      |> expect(:get, fn _url, _headers, _options ->
        {:ok, female_names_response}
      end)
      |> expect(:get, fn _url, _headers, _options ->
        {:ok, male_surnames_response}
      end)
      |> expect(:get, fn _url, _headers, _options ->
        {:ok, female_surnames_response}
      end)

      assert {:ok, data} = PolishDataClient.fetch_all_demographic_data()

      assert %{
               male_names: ["ADAM"],
               female_names: ["ANNA"],
               male_surnames: ["NOWAK"],
               female_surnames: ["KOWALSKA"]
             } = data
    end

    test "fails if any individual fetch fails" do
      error_response = %HTTPoison.Response{
        status_code: 500,
        body: "Internal Server Error",
        headers: [{"content-type", "text/plain"}]
      }

      HTTPoisonMock
      |> expect(:get, fn _url, _headers, _options ->
        {:ok, error_response}
      end)

      assert {:error, {:http_error, 500, "Internal Server Error"}} =
               PolishDataClient.fetch_all_demographic_data()
    end
  end

  describe "make_request/2" do
    test "builds correct URL with default parameters" do
      successful_response = %HTTPoison.Response{
        status_code: 200,
        body: """
        {
          "data": [
            {"attributes": {"col1": {"repr": "TEST"}, "col2": {"repr": "1000"}}}
          ],
          "meta": {"count": 1, "page": 1}
        }
        """,
        headers: [{"content-type", "application/json"}]
      }

      HTTPoisonMock
      |> expect(:get, fn url, _headers, _options ->
        assert String.contains?(url, "resources/12345/data")
        assert String.contains?(url, "page=1")
        assert String.contains?(url, "per_page=100")
        {:ok, successful_response}
      end)

      assert {:ok, _data} = PolishDataClient.make_request("12345")
    end

    test "builds correct URL with custom parameters" do
      successful_response = %HTTPoison.Response{
        status_code: 200,
        body: """
        {
          "data": [
            {"attributes": {"col1": {"repr": "TEST"}, "col2": {"repr": "1000"}}}
          ],
          "meta": {"count": 1, "page": 1}
        }
        """,
        headers: [{"content-type", "application/json"}]
      }

      HTTPoisonMock
      |> expect(:get, fn url, _headers, _options ->
        assert String.contains?(url, "resources/12345/data")
        assert String.contains?(url, "page=2")
        assert String.contains?(url, "per_page=50")
        {:ok, successful_response}
      end)

      assert {:ok, _data} = PolishDataClient.make_request("12345", page: 2, per_page: 50)
    end

    test "handles non-retryable network errors immediately" do
      network_error = %HTTPoison.Error{reason: :nxdomain}

      HTTPoisonMock
      |> expect(:get, fn _url, _headers, _options ->
        {:error, network_error}
      end)

      assert {:error, {:network_error, :nxdomain}} = PolishDataClient.make_request("12345")
    end
  end

  describe "module functions exist" do
    test "has all required public functions" do
      functions = PolishDataClient.__info__(:functions)

      assert Keyword.has_key?(functions, :fetch_male_names)
      assert Keyword.has_key?(functions, :fetch_female_names)
      assert Keyword.has_key?(functions, :fetch_male_surnames)
      assert Keyword.has_key?(functions, :fetch_female_surnames)
      assert Keyword.has_key?(functions, :fetch_all_demographic_data)
      assert Keyword.has_key?(functions, :make_request)
      assert Keyword.has_key?(functions, :parse_response)
    end
  end
end
