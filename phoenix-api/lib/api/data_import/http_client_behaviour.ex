defmodule Api.DataImport.HttpClientBehaviour do
  @moduledoc """
  Behaviour for HTTP client implementations.

  This allows us to mock HTTP requests in tests while using HTTPoison in production.
  """

  @callback get(String.t(), list(), list()) ::
              {:ok, HTTPoison.Response.t()} | {:error, HTTPoison.Error.t()}
end
