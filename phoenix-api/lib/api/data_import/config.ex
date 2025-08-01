defmodule Api.DataImport.Config do
  @moduledoc """
  Configuration module for Data Import functionality.

  Provides centralized access to configuration settings for the Polish data import system,
  including API endpoints, timeouts, and authentication settings.
  """

  @doc """
  Gets the base URL for the dane.gov.pl API.
  """
  def api_base_url do
    Application.get_env(:api, Api.DataImport, [])
    |> Keyword.get(:api_base_url, "https://api.dane.gov.pl/1.4")
  end

  @doc """
  Gets the HTTP request timeout in milliseconds.
  """
  def request_timeout do
    Application.get_env(:api, Api.DataImport, [])
    |> Keyword.get(:request_timeout, 30_000)
  end

  @doc """
  Gets the maximum number of retry attempts for failed requests.
  """
  def max_retries do
    Application.get_env(:api, Api.DataImport, [])
    |> Keyword.get(:max_retries, 3)
  end

  @doc """
  Gets the optional API token for import endpoint authentication.
  Returns nil if no token is configured.
  """
  def import_api_token do
    Application.get_env(:api, Api.DataImport, [])
    |> Keyword.get(:import_api_token)
  end

  @doc """
  Gets the resource IDs for different data types from the dane.gov.pl API.
  """
  def resource_ids do
    %{
      male_names: "63929",
      female_names: "63924",
      male_surnames: "63892",
      female_surnames: "63888"
    }
  end

  @doc """
  Gets the number of records to fetch per API request.
  """
  def per_page do
    100
  end

  @doc """
  Gets the number of users to generate during import.
  """
  def users_to_generate do
    100
  end

  @doc """
  Gets the birth date range for generated users.
  """
  def birth_date_range do
    {~D[1970-01-01], ~D[2024-12-31]}
  end

  @doc """
  Gets HTTPoison options for API requests.
  """
  def http_options do
    [
      timeout: request_timeout(),
      recv_timeout: request_timeout(),
      hackney: [
        pool: :default,
        use_default_pool: true
      ]
    ]
  end

  @doc """
  Gets headers for API requests.
  """
  def http_headers do
    [
      {"Accept", "application/json"},
      {"Content-Type", "application/json"},
      {"User-Agent", "Phoenix-API-DataImport/1.0"}
    ]
  end
end
