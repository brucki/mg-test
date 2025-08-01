defmodule Api.DataImport.HTTPoisonAdapter do
  @moduledoc """
  HTTPoison adapter that implements the HttpClientBehaviour.

  This is the production implementation that makes real HTTP requests.
  """

  @behaviour Api.DataImport.HttpClientBehaviour

  @impl true
  def get(url, headers, options) do
    HTTPoison.get(url, headers, options)
  end
end
