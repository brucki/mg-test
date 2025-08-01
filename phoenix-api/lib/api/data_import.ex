defmodule Api.DataImport do
  @moduledoc """
  Main service module for importing Polish demographic data and generating users.

  This module orchestrates the complete import process:
  1. Fetches demographic data from dane.gov.pl API
  2. Generates random users with proper demographic constraints
  3. Persists users to the database with transaction management
  4. Provides comprehensive error handling and logging
  """

  require Logger
  alias Api.DataImport.{PolishDataClient, UserGenerator, Config}
  alias Api.{Accounts, Repo}

  # Allow client to be configured for testing
  defp polish_data_client do
    Application.get_env(:api, :polish_data_client, PolishDataClient)
  end

  @doc """
  Imports Polish demographic data and generates random users.

  This is the main entry point for the import process. It coordinates:
  - Fetching demographic data from external APIs
  - Generating random users with proper constraints
  - Batch inserting users into the database
  - Comprehensive error handling and rollback

  ## Returns
  - {:ok, count} on successful import with number of users created
  - {:error, reason} on failure with detailed error information

  ## Examples

      iex> Api.DataImport.import_polish_users()
      {:ok, 100}

      iex> Api.DataImport.import_polish_users()
      {:error, {:api_error, :network_timeout}}
  """
  def import_polish_users do
    import_id = generate_import_id()

    Logger.info("Starting Polish users import process", %{
      import_id: import_id,
      process_pid: inspect(self()),
      timestamp: DateTime.utc_now()
    })

    start_time = System.monotonic_time(:millisecond)

    try do
      with {:ok, demographic_data} <- fetch_demographic_data(),
           {:ok, users_attrs} <- generate_random_users(demographic_data),
           {:ok, count} <- save_users_to_database(users_attrs) do
        end_time = System.monotonic_time(:millisecond)
        duration = end_time - start_time

        Logger.info("Successfully completed Polish users import", %{
          import_id: import_id,
          users_imported: count,
          total_duration_ms: duration,
          avg_time_per_user_ms: Float.round(duration / count, 2),
          completion_timestamp: DateTime.utc_now()
        })

        {:ok, count}
      else
        {:error, reason} ->
          end_time = System.monotonic_time(:millisecond)
          duration = end_time - start_time

          Logger.error("Import process failed", %{
            import_id: import_id,
            failure_reason: reason,
            total_duration_ms: duration,
            failure_timestamp: DateTime.utc_now()
          })

          handle_import_error(reason)
      end
    rescue
      error ->
        end_time = System.monotonic_time(:millisecond)
        duration = end_time - start_time

        Logger.error("Unexpected exception during import", %{
          import_id: import_id,
          exception: error,
          stacktrace: __STACKTRACE__,
          duration_ms: duration
        })

        {:error, {:unexpected_import_exception, error}}
    catch
      :exit, reason ->
        end_time = System.monotonic_time(:millisecond)
        duration = end_time - start_time

        Logger.error("Process exit during import", %{
          import_id: import_id,
          exit_reason: reason,
          duration_ms: duration
        })

        {:error, {:import_process_exit, reason}}

      :throw, reason ->
        end_time = System.monotonic_time(:millisecond)
        duration = end_time - start_time

        Logger.error("Throw during import", %{
          import_id: import_id,
          throw_reason: reason,
          duration_ms: duration
        })

        {:error, {:import_throw_error, reason}}
    end
  end

  @doc """
  Fetches all required demographic data from the dane.gov.pl API.

  Coordinates the fetching of:
  - Male names (100 most popular)
  - Female names (100 most popular)
  - Male surnames (100 most popular)
  - Female surnames (100 most popular)

  ## Returns
  - {:ok, demographic_data} with all required data
  - {:error, reason} if any API call fails
  """
  def fetch_demographic_data do
    Logger.info("Starting demographic data fetch from dane.gov.pl API", %{
      api_base_url: Config.api_base_url(),
      max_retries: Config.max_retries(),
      request_timeout: Config.request_timeout()
    })

    start_time = System.monotonic_time(:millisecond)

    try do
      case polish_data_client().fetch_all_demographic_data() do
        {:ok, data} ->
          end_time = System.monotonic_time(:millisecond)
          duration = end_time - start_time

          Logger.info("Successfully fetched all demographic data", %{
            fetch_duration_ms: duration,
            data_summary: %{
              male_names: length(Map.get(data, :male_names, [])),
              female_names: length(Map.get(data, :female_names, [])),
              male_surnames: length(Map.get(data, :male_surnames, [])),
              female_surnames: length(Map.get(data, :female_surnames, []))
            }
          })

          validate_demographic_data(data)

        {:error, reason} = error ->
          end_time = System.monotonic_time(:millisecond)
          duration = end_time - start_time

          Logger.error("Failed to fetch demographic data", %{
            error: reason,
            fetch_duration_ms: duration
          })

          error
      end
    rescue
      error ->
        end_time = System.monotonic_time(:millisecond)
        duration = end_time - start_time

        Logger.error("Exception during demographic data fetch", %{
          exception: error,
          stacktrace: __STACKTRACE__,
          duration_ms: duration
        })

        {:error, {:demographic_fetch_exception, error}}
    end
  end

  @doc """
  Generates random users using the provided demographic data.

  Creates exactly 100 random users with:
  - Gender-consistent names and surnames
  - Random birthdates between 1970-2024
  - Proper data validation

  ## Parameters
  - demographic_data: Map containing male_names, female_names, male_surnames, female_surnames

  ## Returns
  - {:ok, users_attrs} list of user attribute maps
  - {:error, reason} if generation fails
  """
  def generate_random_users(demographic_data) do
    target_count = Config.users_to_generate()

    Logger.info("Starting random user generation", %{
      target_user_count: target_count,
      demographic_data_summary: %{
        male_names: length(Map.get(demographic_data, :male_names, [])),
        female_names: length(Map.get(demographic_data, :female_names, [])),
        male_surnames: length(Map.get(demographic_data, :male_surnames, [])),
        female_surnames: length(Map.get(demographic_data, :female_surnames, []))
      }
    })

    start_time = System.monotonic_time(:millisecond)

    try do
      case UserGenerator.generate_users(demographic_data) do
        {:ok, users_attrs} ->
          end_time = System.monotonic_time(:millisecond)
          duration = end_time - start_time

          Logger.info("Successfully generated random users", %{
            generated_count: length(users_attrs),
            target_count: target_count,
            generation_duration_ms: duration,
            avg_generation_time_ms: Float.round(duration / length(users_attrs), 2)
          })

          {:ok, users_attrs}

        {:error, reason} = error ->
          end_time = System.monotonic_time(:millisecond)
          duration = end_time - start_time

          Logger.error("Failed to generate users", %{
            error: reason,
            target_count: target_count,
            generation_duration_ms: duration
          })

          error
      end
    rescue
      error ->
        end_time = System.monotonic_time(:millisecond)
        duration = end_time - start_time

        Logger.error("Exception during user generation", %{
          exception: error,
          stacktrace: __STACKTRACE__,
          duration_ms: duration
        })

        {:error, {:user_generation_exception, error}}
    end
  end

  @doc """
  Saves a list of users to the database using batch operations and transactions.

  Performs batch insertion with:
  - Database transaction for consistency
  - Rollback on any failure
  - Detailed logging of the process

  ## Parameters
  - users_attrs: List of user attribute maps

  ## Returns
  - {:ok, count} number of users successfully saved
  - {:error, reason} if database operation fails
  """
  def save_users_to_database(users_attrs) when is_list(users_attrs) do
    Logger.info("Starting database save operation", %{
      users_to_save: length(users_attrs),
      sample_user: List.first(users_attrs),
      database_repo: Api.Repo
    })

    start_time = System.monotonic_time(:millisecond)

    try do
      case batch_insert_users(users_attrs) do
        {:ok, count} ->
          end_time = System.monotonic_time(:millisecond)
          duration = end_time - start_time

          Logger.info("Successfully saved users to database", %{
            saved_count: count,
            target_count: length(users_attrs),
            save_duration_ms: duration,
            avg_save_time_ms: Float.round(duration / count, 2)
          })

          {:ok, count}

        {:error, reason} = error ->
          end_time = System.monotonic_time(:millisecond)
          duration = end_time - start_time

          Logger.error("Failed to save users to database", %{
            error: reason,
            target_count: length(users_attrs),
            save_duration_ms: duration
          })

          error
      end
    rescue
      error ->
        end_time = System.monotonic_time(:millisecond)
        duration = end_time - start_time

        Logger.error("Exception during database save", %{
          exception: error,
          stacktrace: __STACKTRACE__,
          duration_ms: duration
        })

        {:error, {:database_save_exception, error}}
    end
  end

  # Private functions

  defp batch_insert_users(users_attrs) do
    # Use a database transaction to ensure data consistency
    Repo.transaction(fn ->
      try do
        # Validate all users before attempting to insert any
        case validate_users_batch(users_attrs) do
          {:ok, validated_users} ->
            insert_validated_users(validated_users)

          {:error, validation_errors} ->
            Logger.error("User validation failed before database insertion")
            Repo.rollback({:validation_failed, validation_errors})
        end
      rescue
        error ->
          Logger.error("Unexpected error during batch insert: #{inspect(error)}")
          Repo.rollback({:unexpected_error, error})
      catch
        :exit, reason ->
          Logger.error("Process exit during batch insert: #{inspect(reason)}")
          Repo.rollback({:process_exit, reason})

        :throw, reason ->
          Logger.error("Throw during batch insert: #{inspect(reason)}")
          Repo.rollback({:throw_error, reason})
      end
    end)
    |> handle_transaction_result()
  end

  defp validate_users_batch(users_attrs) do
    Logger.info("Starting pre-insertion validation", %{
      users_to_validate: length(users_attrs),
      validation_step: "pre_database_insertion"
    })

    start_time = System.monotonic_time(:millisecond)

    case UserGenerator.validate_users_batch(users_attrs) do
      {:ok, valid_users} ->
        end_time = System.monotonic_time(:millisecond)
        duration = end_time - start_time

        Logger.info("All users passed pre-insertion validation", %{
          validated_users: length(valid_users),
          validation_duration_ms: duration,
          validation_success_rate: 100.0
        })

        {:ok, valid_users}

      {:error, {valid_users, invalid_users}} ->
        end_time = System.monotonic_time(:millisecond)
        duration = end_time - start_time
        success_rate = Float.round(length(valid_users) / length(users_attrs) * 100, 2)

        Logger.error("Pre-insertion validation completed with failures", %{
          total_users: length(users_attrs),
          valid_users: length(valid_users),
          invalid_users: length(invalid_users),
          validation_duration_ms: duration,
          validation_success_rate: success_rate
        })

        log_validation_errors(invalid_users)
        {:error, {:batch_validation_failed, length(valid_users), length(invalid_users)}}
    end
  end

  defp insert_validated_users(users_attrs) do
    Logger.info("Starting database insertion of validated users", %{
      users_to_insert: length(users_attrs),
      insertion_method: "individual_inserts_with_tracking"
    })

    start_time = System.monotonic_time(:millisecond)

    # Track successful and failed insertions
    {successful_count, failed_insertions} =
      users_attrs
      |> Enum.with_index()
      |> Enum.reduce({0, []}, fn {user_attrs, index}, {success_count, failures} ->
        case insert_single_user(user_attrs, index) do
          {:ok, _user} ->
            if rem(success_count + 1, 25) == 0 do
              Logger.debug(
                "Insertion progress: #{success_count + 1}/#{length(users_attrs)} users"
              )
            end

            {success_count + 1, failures}

          {:error, reason} ->
            {success_count, [{index, user_attrs, reason} | failures]}
        end
      end)

    end_time = System.monotonic_time(:millisecond)
    duration = end_time - start_time

    case failed_insertions do
      [] ->
        Logger.info("Successfully inserted all users", %{
          inserted_count: successful_count,
          insertion_duration_ms: duration,
          avg_insertion_time_ms: Float.round(duration / successful_count, 2)
        })

        successful_count

      failures ->
        Logger.error("Database insertion completed with failures", %{
          successful_insertions: successful_count,
          failed_insertions: length(failures),
          insertion_duration_ms: duration,
          failure_rate: Float.round(length(failures) / length(users_attrs) * 100, 2)
        })

        log_insertion_errors(failures)
        Repo.rollback({:partial_insertion_failure, successful_count, failures})
    end
  end

  defp insert_single_user(user_attrs, index) do
    Logger.debug("Inserting user at index #{index}", %{
      index: index,
      user_attrs: user_attrs
    })

    case Accounts.create_user(user_attrs) do
      {:ok, user} ->
        Logger.debug("Successfully created user", %{
          index: index,
          user_id: user.id,
          first_name: user.first_name,
          last_name: user.last_name
        })

        {:ok, user}

      {:error, changeset} ->
        Logger.warning("User creation failed due to changeset errors", %{
          index: index,
          user_attrs: user_attrs,
          changeset_errors: changeset.errors,
          changeset_valid: changeset.valid?
        })

        {:error, {:changeset_error, changeset.errors}}
    end
  rescue
    error ->
      Logger.error("Exception during user creation", %{
        index: index,
        user_attrs: user_attrs,
        exception: error,
        stacktrace: __STACKTRACE__
      })

      {:error, {:creation_exception, error}}
  end

  defp handle_transaction_result(transaction_result) do
    case transaction_result do
      {:ok, count} when is_integer(count) ->
        {:ok, count}

      {:error, {:validation_failed, errors}} ->
        {:error, {:pre_insertion_validation_failed, errors}}

      {:error, {:partial_insertion_failure, successful_count, failures}} ->
        {:error, {:database_insertion_failed, successful_count, length(failures)}}

      {:error, {:unexpected_error, error}} ->
        {:error, {:unexpected_database_error, error}}

      {:error, {:process_exit, reason}} ->
        {:error, {:database_process_exit, reason}}

      {:error, {:throw_error, reason}} ->
        {:error, {:database_throw_error, reason}}

      {:error, reason} ->
        {:error, {:database_transaction_failed, reason}}
    end
  end

  defp log_validation_errors(invalid_users) do
    invalid_users
    # Log only first 5 to avoid spam
    |> Enum.take(5)
    |> Enum.each(fn {index, _user_attrs, errors} ->
      Logger.error("User validation failed at index #{index}: #{inspect(errors)}")
    end)

    if length(invalid_users) > 5 do
      Logger.error("... and #{length(invalid_users) - 5} more validation errors")
    end
  end

  defp log_insertion_errors(failed_insertions) do
    failed_insertions
    # Log only first 5 to avoid spam
    |> Enum.take(5)
    |> Enum.each(fn {index, _user_attrs, reason} ->
      Logger.error("User insertion failed at index #{index}: #{inspect(reason)}")
    end)

    if length(failed_insertions) > 5 do
      Logger.error("... and #{length(failed_insertions) - 5} more insertion errors")
    end
  end

  defp handle_import_error(reason) do
    case reason do
      {:network_error, _} ->
        {:error, {:api_connection_failed, "Unable to connect to dane.gov.pl API"}}

      {:http_error, status_code, _body} ->
        {:error, {:api_http_error, "API returned HTTP #{status_code}"}}

      {:json_parse_error, _} ->
        {:error, {:api_response_invalid, "Invalid JSON response from API"}}

      {:no_valid_names_found} ->
        {:error, {:api_data_invalid, "No valid names found in API response"}}

      {:no_valid_users_generated} ->
        {:error, {:user_generation_failed, "Unable to generate valid users"}}

      {:pre_insertion_validation_failed, _} ->
        {:error, {:validation_failed, "Generated users failed validation"}}

      {:database_insertion_failed, successful, failed} ->
        {:error, {:partial_database_failure, "#{successful} users saved, #{failed} failed"}}

      {:unexpected_database_error, _} ->
        {:error, {:database_error, "Unexpected database error occurred"}}

      other ->
        {:error, {:unknown_import_error, other}}
    end
  end

  defp validate_demographic_data(data) do
    required_keys = [:male_names, :female_names, :male_surnames, :female_surnames]

    case Enum.all?(required_keys, &Map.has_key?(data, &1)) do
      true ->
        case validate_demographic_data_content(data, required_keys) do
          :ok ->
            {:ok, data}

          {:error, reason} ->
            Logger.error("Demographic data validation failed: #{inspect(reason)}")
            {:error, {:invalid_demographic_data, reason}}
        end

      false ->
        missing_keys = required_keys -- Map.keys(data)
        Logger.error("Missing required demographic data keys: #{inspect(missing_keys)}")
        {:error, {:missing_demographic_keys, missing_keys}}
    end
  end

  defp validate_demographic_data_content(data, keys) do
    case Enum.find(keys, fn key ->
           list = Map.get(data, key)
           not is_list(list) or length(list) == 0
         end) do
      nil ->
        :ok

      invalid_key ->
        {:error, {:empty_or_invalid_list, invalid_key}}
    end
  end

  defp generate_import_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end
end
