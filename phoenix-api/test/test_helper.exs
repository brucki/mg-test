ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Api.Repo, :manual)

# Set up Mox for HTTP client mocking
Mox.defmock(HTTPoisonMock, for: HTTPoison.Base)

# Set up Mox for PolishDataClient mocking
Mox.defmock(Api.DataImport.PolishDataClientMock, for: Api.DataImport.PolishDataClientBehaviour)
