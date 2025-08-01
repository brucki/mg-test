defmodule Api.DataImport.PolishDataClient do
  @moduledoc """
  HTTP client for fetching Polish demographic data from the dane.gov.pl API.

  This module handles communication with the official Polish government API
  to fetch names and surnames data with proper error handling and retry logic.
  """

  @behaviour Api.DataImport.PolishDataClientBehaviour

  require Logger
  alias Api.DataImport.Config

  @doc """
  Fetches the 100 most popular male names from the dane.gov.pl API.

  ## Returns
  - {:ok, [names]} on success
  - {:error, reason} on failure
  """
  def fetch_male_names do
    resource_id = Config.resource_ids().male_names
    Logger.info("Fetching male names from resource #{resource_id}")
    start_time = System.monotonic_time(:millisecond)

    case make_request(resource_id) do
      {:ok, names} ->
        end_time = System.monotonic_time(:millisecond)
        duration = end_time - start_time

        Logger.info("Successfully fetched #{length(names)} male names in #{duration}ms", %{
          resource_id: resource_id,
          count: length(names),
          duration_ms: duration,
          data_type: "male_names"
        })

        {:ok, names}

      {:error, reason} ->
        end_time = System.monotonic_time(:millisecond)
        duration = end_time - start_time

        Logger.error("Failed to fetch male names after #{duration}ms: #{inspect(reason)}", %{
          resource_id: resource_id,
          duration_ms: duration,
          error: reason,
          data_type: "male_names"
        })

        {:error, reason}
    end
  end

  @doc """
  Fetches the 100 most popular female names from the dane.gov.pl API.

  ## Returns
  - {:ok, [names]} on success
  - {:error, reason} on failure
  """
  def fetch_female_names do
    resource_id = Config.resource_ids().female_names
    Logger.info("Fetching female names from resource #{resource_id}")
    start_time = System.monotonic_time(:millisecond)

    case make_request(resource_id) do
      {:ok, names} ->
        end_time = System.monotonic_time(:millisecond)
        duration = end_time - start_time

        Logger.info("Successfully fetched #{length(names)} female names in #{duration}ms", %{
          resource_id: resource_id,
          count: length(names),
          duration_ms: duration,
          data_type: "female_names"
        })

        {:ok, names}

      {:error, reason} ->
        end_time = System.monotonic_time(:millisecond)
        duration = end_time - start_time

        Logger.error("Failed to fetch female names after #{duration}ms: #{inspect(reason)}", %{
          resource_id: resource_id,
          duration_ms: duration,
          error: reason,
          data_type: "female_names"
        })

        {:error, reason}
    end
  end

  @doc """
  Fetches the 100 most popular male surnames from the dane.gov.pl API.

  ## Returns
  - {:ok, [surnames]} on success
  - {:error, reason} on failure
  """
  def fetch_male_surnames do
    resource_id = Config.resource_ids().male_surnames
    Logger.info("Fetching male surnames from resource #{resource_id}")
    start_time = System.monotonic_time(:millisecond)

    case make_request(resource_id) do
      {:ok, surnames} ->
        end_time = System.monotonic_time(:millisecond)
        duration = end_time - start_time

        Logger.info("Successfully fetched #{length(surnames)} male surnames in #{duration}ms", %{
          resource_id: resource_id,
          count: length(surnames),
          duration_ms: duration,
          data_type: "male_surnames"
        })

        {:ok, surnames}

      {:error, reason} ->
        end_time = System.monotonic_time(:millisecond)
        duration = end_time - start_time

        Logger.error("Failed to fetch male surnames after #{duration}ms: #{inspect(reason)}", %{
          resource_id: resource_id,
          duration_ms: duration,
          error: reason,
          data_type: "male_surnames"
        })

        {:error, reason}
    end
  end

  @doc """
  Fetches the 100 most popular female surnames from the dane.gov.pl API.

  ## Returns
  - {:ok, [surnames]} on success
  - {:error, reason} on failure
  """
  def fetch_female_surnames do
    resource_id = Config.resource_ids().female_surnames
    Logger.info("Fetching female surnames from resource #{resource_id}")
    start_time = System.monotonic_time(:millisecond)

    case make_request(resource_id) do
      {:ok, surnames} ->
        end_time = System.monotonic_time(:millisecond)
        duration = end_time - start_time

        Logger.info(
          "Successfully fetched #{length(surnames)} female surnames in #{duration}ms",
          %{
            resource_id: resource_id,
            count: length(surnames),
            duration_ms: duration,
            data_type: "female_surnames"
          }
        )

        {:ok, surnames}

      {:error, reason} ->
        end_time = System.monotonic_time(:millisecond)
        duration = end_time - start_time

        Logger.error("Failed to fetch female surnames after #{duration}ms: #{inspect(reason)}", %{
          resource_id: resource_id,
          duration_ms: duration,
          error: reason,
          data_type: "female_surnames"
        })

        {:error, reason}
    end
  end

  @doc """
  Fetches all demographic data (names and surnames) in a single operation.

  ## Returns
  - {:ok, %{male_names: [...], female_names: [...], male_surnames: [...], female_surnames: [...]}} on success
  - {:error, reason} on failure
  """
  def fetch_all_demographic_data do
    Logger.info("Starting to fetch all demographic data from dane.gov.pl API")
    start_time = System.monotonic_time(:millisecond)

    with {:ok, male_names} <- fetch_male_names(),
         {:ok, female_names} <- fetch_female_names(),
         {:ok, male_surnames} <- fetch_male_surnames(),
         {:ok, female_surnames} <- fetch_female_surnames() do
      end_time = System.monotonic_time(:millisecond)
      duration = end_time - start_time

      result = %{
        male_names: male_names,
        female_names: female_names,
        male_surnames: male_surnames,
        female_surnames: female_surnames
      }

      total_records =
        length(male_names) + length(female_names) +
          length(male_surnames) + length(female_surnames)

      Logger.info("Successfully fetched all demographic data in #{duration}ms", %{
        total_duration_ms: duration,
        total_records: total_records,
        male_names_count: length(male_names),
        female_names_count: length(female_names),
        male_surnames_count: length(male_surnames),
        female_surnames_count: length(female_surnames)
      })

      {:ok, result}
    else
      {:error, reason} = error ->
        end_time = System.monotonic_time(:millisecond)
        duration = end_time - start_time

        Logger.error(
          "Failed to fetch all demographic data after #{duration}ms: #{inspect(reason)}",
          %{
            total_duration_ms: duration,
            error: reason
          }
        )

        error
    end
  end

  @doc """
  Makes an HTTP request to the dane.gov.pl API with retry logic.

  ## Parameters
  - resource_id: The API resource identifier
  - params: Additional query parameters (optional)

  ## Returns
  - {:ok, data} on success
  - {:error, reason} on failure
  """
  def make_request(resource_id, params \\ []) do
    url = build_url(resource_id, params)
    headers = Config.http_headers()
    options = Config.http_options()

    Logger.info("Making API request to dane.gov.pl", %{
      url: url,
      resource_id: resource_id,
      params: params,
      headers: Enum.into(headers, %{}),
      timeout: options[:timeout]
    })

    request_start = System.monotonic_time(:millisecond)

    case make_request_with_retry(url, headers, options, Config.max_retries()) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body} = response} ->
        request_end = System.monotonic_time(:millisecond)
        request_duration = request_end - request_start

        Logger.info("API request successful", %{
          resource_id: resource_id,
          status_code: 200,
          response_size_bytes: byte_size(body),
          request_duration_ms: request_duration,
          content_type: get_header_value(response.headers, "content-type")
        })

        parse_response(body)

      {:ok, %HTTPoison.Response{status_code: status_code, body: body} = response} ->
        request_end = System.monotonic_time(:millisecond)
        request_duration = request_end - request_start

        Logger.error("API request failed with HTTP error", %{
          resource_id: resource_id,
          status_code: status_code,
          # Log first 500 chars
          response_body: String.slice(body, 0, 500),
          request_duration_ms: request_duration,
          content_type: get_header_value(response.headers, "content-type")
        })

        {:error, {:http_error, status_code, body}}

      {:error, %HTTPoison.Error{reason: reason}} ->
        request_end = System.monotonic_time(:millisecond)
        request_duration = request_end - request_start

        Logger.error("HTTP request failed with network error", %{
          resource_id: resource_id,
          error_reason: reason,
          request_duration_ms: request_duration,
          url: url
        })

        {:error, {:network_error, reason}}

      {:error, reason} ->
        request_end = System.monotonic_time(:millisecond)
        request_duration = request_end - request_start

        Logger.error("Request failed with unknown error", %{
          resource_id: resource_id,
          error: reason,
          request_duration_ms: request_duration,
          url: url
        })

        {:error, reason}
    end
  end

  @doc """
  Parses the JSON response from the API and extracts the data.

  ## Parameters
  - response_body: Raw JSON response string

  ## Returns
  - {:ok, parsed_data} on successful parsing
  - {:error, reason} on parsing failure
  """
  def parse_response(response_body) when is_binary(response_body) do
    Logger.debug("Parsing API response", %{
      response_size_bytes: byte_size(response_body),
      response_preview: String.slice(response_body, 0, 200)
    })

    case Jason.decode(response_body) do
      {:ok, %{"data" => data} = response} when is_list(data) ->
        Logger.debug("JSON parsing successful", %{
          data_count: length(data),
          has_meta: Map.has_key?(response, "meta"),
          meta: Map.get(response, "meta", %{})
        })

        case extract_names_from_data(data) do
          {:ok, parsed_data} ->
            Logger.info("Successfully parsed #{length(parsed_data)} records from API response", %{
              raw_records: length(data),
              valid_records: length(parsed_data),
              parsing_success_rate: Float.round(length(parsed_data) / length(data) * 100, 2)
            })

            {:ok, parsed_data}

          {:error, reason} = error ->
            Logger.error("Failed to extract names from data", %{
              error: reason,
              raw_data_count: length(data),
              sample_record: List.first(data)
            })

            error
        end

      {:ok, response} ->
        Logger.error("Unexpected API response structure", %{
          response_keys: Map.keys(response),
          has_data_key: Map.has_key?(response, "data"),
          data_type: if(Map.has_key?(response, "data"), do: typeof(response["data"]), else: nil),
          response_sample: inspect(response) |> String.slice(0, 500)
        })

        {:error, {:invalid_response_structure, response}}

      {:error, reason} ->
        Logger.error("Failed to parse JSON response", %{
          json_error: reason,
          response_size: byte_size(response_body),
          response_preview: String.slice(response_body, 0, 200)
        })

        {:error, {:json_parse_error, reason}}
    end
  end

  # Private functions

  defp http_client do
    Application.get_env(:api, :http_client, Api.DataImport.HTTPoisonAdapter)
  end

  defp build_url(resource_id, params) do
    base_url = Config.api_base_url()
    default_params = [page: 1, per_page: Config.per_page()]
    query_params = Keyword.merge(default_params, params)
    query_string = URI.encode_query(query_params)

    "#{base_url}/resources/#{resource_id}/data?#{query_string}"
  end

  defp make_request_with_retry(url, headers, options, retries_left) when retries_left > 0 do
    attempt_number = Config.max_retries() - retries_left + 1

    Logger.debug("Making HTTP request attempt #{attempt_number}/#{Config.max_retries()}", %{
      url: url,
      attempt: attempt_number,
      retries_left: retries_left,
      timeout: options[:timeout]
    })

    case http_client().get(url, headers, options) do
      {:ok, response} ->
        if attempt_number > 1 do
          Logger.info("Request succeeded on attempt #{attempt_number}", %{
            url: url,
            attempt: attempt_number,
            status_code: response.status_code
          })
        end

        {:ok, response}

      {:error, %HTTPoison.Error{reason: reason}} = error ->
        if should_retry?(reason) and retries_left > 1 do
          delay = calculate_backoff_delay(attempt_number)

          Logger.warning("Request failed, retrying with exponential backoff", %{
            url: url,
            attempt: attempt_number,
            error_reason: reason,
            retries_left: retries_left - 1,
            retry_delay_ms: delay,
            will_retry: true
          })

          Process.sleep(delay)
          make_request_with_retry(url, headers, options, retries_left - 1)
        else
          Logger.error("Request failed after all retry attempts", %{
            url: url,
            final_attempt: attempt_number,
            total_attempts: Config.max_retries(),
            final_error: reason,
            retry_eligible: should_retry?(reason)
          })

          error
        end
    end
  end

  defp make_request_with_retry(_url, _headers, _options, 0) do
    {:error, :max_retries_exceeded}
  end

  defp should_retry?(reason) do
    case reason do
      :timeout -> true
      :connect_timeout -> true
      :checkout_timeout -> true
      :econnrefused -> true
      :nxdomain -> false
      :closed -> true
      _ -> false
    end
  end

  defp calculate_backoff_delay(attempt) do
    # Exponential backoff: 1s, 2s, 4s, etc.
    base_delay = 1000
    (:math.pow(2, attempt - 1) * base_delay) |> round()
  end

  defp extract_names_from_data(data) when is_list(data) do
    names =
      data
      |> Enum.map(&extract_name_from_record/1)
      |> Enum.filter(& &1)

    validate_extracted_names(names)
  end

  defp extract_name_from_record(record) when is_map(record) do
    record["attributes"]["col1"]["repr"]
    |> String.trim()
    |> String.upcase()
    |> case do
      "" ->
        nil

      cleaned_name ->
        if valid_name?(cleaned_name) do
          cleaned_name
        else
          Logger.warning("Skipping invalid name: #{cleaned_name}")
          nil
        end
    end
  end

  defp extract_name_from_record(record) do
    Logger.warning("Skipping invalid record structure: #{inspect(record)}")
    nil
  end

  defp validate_extracted_names(names) when is_list(names) do
    case length(names) do
      0 ->
        {:error, :no_valid_names_found}

      count when count < 10 ->
        Logger.warning("Only #{count} valid names found, expected around 100")
        {:ok, names}

      _count ->
        {:ok, names}
    end
  end

  defp valid_name?(name) when is_binary(name) do
    # Basic validation: name should contain only letters, spaces, and hyphens
    # and be between 2 and 50 characters
    String.length(name) >= 2 and
      String.length(name) <= 50 and
      Regex.match?(~r/^[A-ZĄĆĘŁŃÓŚŹŻ\s\-]+$/u, name)
  end

  defp get_header_value(headers, key) when is_list(headers) do
    headers
    |> Enum.find(fn {header_key, _value} ->
      String.downcase(header_key) == String.downcase(key)
    end)
    |> case do
      {_key, value} -> value
      nil -> nil
    end
  end

  defp typeof(value) do
    cond do
      is_list(value) -> "list"
      is_map(value) -> "map"
      is_binary(value) -> "string"
      is_integer(value) -> "integer"
      is_float(value) -> "float"
      is_boolean(value) -> "boolean"
      is_nil(value) -> "nil"
      true -> "unknown"
    end
  end
end
