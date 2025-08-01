#!/bin/sh

cd /app

# Run migrations with proper error handling
/app/bin/api eval "
  # Ensure all applications are started
  {:ok, _} = Application.ensure_all_started(:api)
  
  # Run migrations
  case Ecto.Migrator.run(Api.Repo, :up, all: true) do
    {:ok, _, _} -> 
      IO.puts(\"Migrations completed successfully\")
      System.halt(0)
    {:error, reason} -> 
      IO.puts(\"Migration failed: #{inspect(reason)}\")
      System.halt(1)
    result -> 
      IO.puts(\"Migration result: #{inspect(result)}\")
      System.halt(0)
  end
"
