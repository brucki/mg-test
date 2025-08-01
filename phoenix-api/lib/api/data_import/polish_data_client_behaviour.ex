defmodule Api.DataImport.PolishDataClientBehaviour do
  @moduledoc """
  Behaviour for Polish Data Client to enable mocking in tests.
  """

  @callback fetch_all_demographic_data() :: {:ok, map()} | {:error, term()}
  @callback fetch_male_names() :: {:ok, list()} | {:error, term()}
  @callback fetch_female_names() :: {:ok, list()} | {:error, term()}
  @callback fetch_male_surnames() :: {:ok, list()} | {:error, term()}
  @callback fetch_female_surnames() :: {:ok, list()} | {:error, term()}
end
