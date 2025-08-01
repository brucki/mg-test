defmodule Api.DataImport.UserGenerator do
  @moduledoc """
  Generates random users with realistic Polish demographic data.

  This module creates random users using Polish names and surnames fetched from
  the dane.gov.pl API, ensuring gender consistency and proper data formatting.
  """

  require Logger
  alias Api.DataImport.Config

  @doc """
  Generates a specified number of random users with Polish demographic data.

  ## Parameters
  - names_data: Map containing male_names, female_names, male_surnames, female_surnames
  - count: Number of users to generate (defaults to 100)

  ## Returns
  - {:ok, [user_attrs]} on success
  - {:error, reason} on failure

  ## Examples

      iex> names_data = %{
      ...>   male_names: ["ADAM", "ANDRZEJ"],
      ...>   female_names: ["ANNA", "MARIA"],
      ...>   male_surnames: ["NOWAK", "KOWALSKI"],
      ...>   female_surnames: ["NOWAK", "KOWALSKA"]
      ...> }
      iex> UserGenerator.generate_users(names_data, 2)
      {:ok, [%{first_name: "Adam", last_name: "Nowak", gender: :male, birthdate: ~D[1985-06-15]}, ...]}
  """
  def generate_users(names_data, count \\ nil) do
    count = count || Config.users_to_generate()

    Logger.info("Starting generation of #{count} random users", %{
      target_count: count,
      available_male_names: length(Map.get(names_data, :male_names, [])),
      available_female_names: length(Map.get(names_data, :female_names, [])),
      available_male_surnames: length(Map.get(names_data, :male_surnames, [])),
      available_female_surnames: length(Map.get(names_data, :female_surnames, []))
    })

    start_time = System.monotonic_time(:millisecond)

    case validate_names_data(names_data) do
      :ok ->
        Logger.debug("Names data validation passed, proceeding with user generation")
        {users, failed_count} = generate_users_with_retry(names_data, count)

        end_time = System.monotonic_time(:millisecond)
        duration = end_time - start_time

        case length(users) do
          ^count ->
            Logger.info("Successfully generated #{count} users in #{duration}ms", %{
              generated_count: count,
              failed_attempts: failed_count,
              generation_duration_ms: duration,
              success_rate: 100.0
            })

            {:ok, users}

          actual_count when actual_count > 0 ->
            success_rate = Float.round(actual_count / count * 100, 2)

            Logger.warning("Partial user generation success", %{
              requested_count: count,
              generated_count: actual_count,
              failed_attempts: failed_count,
              generation_duration_ms: duration,
              success_rate: success_rate
            })

            {:ok, users}

          0 ->
            Logger.error("Failed to generate any valid users", %{
              requested_count: count,
              failed_attempts: failed_count,
              generation_duration_ms: duration,
              names_data_summary: summarize_names_data(names_data)
            })

            {:error, :no_valid_users_generated}
        end

      {:error, reason} = error ->
        end_time = System.monotonic_time(:millisecond)
        duration = end_time - start_time

        Logger.error("User generation failed during validation", %{
          validation_error: reason,
          duration_ms: duration,
          names_data_summary: summarize_names_data(names_data)
        })

        error
    end
  end

  @doc """
  Validates that a list of user attributes would pass User changeset validation.

  ## Parameters
  - users_attrs: List of user attribute maps

  ## Returns
  - {:ok, valid_users} on success
  - {:error, {invalid_users, errors}} on validation failures
  """
  def validate_users_batch(users_attrs) when is_list(users_attrs) do
    Logger.info("Starting batch validation of #{length(users_attrs)} users")
    start_time = System.monotonic_time(:millisecond)

    {valid_users, invalid_users} =
      users_attrs
      |> Enum.with_index()
      |> Enum.reduce({[], []}, fn {user_attrs, index}, {valid, invalid} ->
        case validate_with_changeset(user_attrs) do
          :ok ->
            {[user_attrs | valid], invalid}

          {:error, reason} ->
            Logger.debug("User validation failed at index #{index}", %{
              index: index,
              user_attrs: user_attrs,
              validation_error: reason
            })

            {valid, [{index, user_attrs, reason} | invalid]}
        end
      end)

    end_time = System.monotonic_time(:millisecond)
    duration = end_time - start_time

    case invalid_users do
      [] ->
        Logger.info("All users passed batch validation", %{
          total_users: length(users_attrs),
          valid_users: length(valid_users),
          validation_duration_ms: duration
        })

        {:ok, Enum.reverse(valid_users)}

      errors ->
        Logger.warning("Batch validation completed with errors", %{
          total_users: length(users_attrs),
          valid_users: length(valid_users),
          invalid_users: length(errors),
          validation_duration_ms: duration,
          error_sample: Enum.take(errors, 3)
        })

        {:error, {Enum.reverse(valid_users), Enum.reverse(errors)}}
    end
  end

  @doc """
  Generates a single random user with Polish demographic data.

  ## Parameters
  - names_data: Map containing male_names, female_names, male_surnames, female_surnames

  ## Returns
  - User attributes map or nil if generation fails
  """
  def generate_random_user(names_data) do
    try do
      # First select gender randomly
      gender = select_random_gender()
      Logger.debug("Generating user with gender: #{gender}")

      # Then select appropriate name and surname based on gender
      first_name = select_random_name(names_data, gender)
      last_name = select_random_surname(names_data, gender)
      birthdate = generate_random_birthdate()

      user_attrs = %{
        first_name: format_name(first_name),
        last_name: format_name(last_name),
        gender: gender,
        birthdate: birthdate
      }

      Logger.debug("Generated user attributes", %{
        first_name: user_attrs.first_name,
        last_name: user_attrs.last_name,
        gender: user_attrs.gender,
        birthdate: user_attrs.birthdate,
        raw_first_name: first_name,
        raw_last_name: last_name
      })

      # Validate the generated data would pass User changeset validation
      case validate_user_attrs(user_attrs) do
        :ok ->
          user_attrs

        {:error, reason} ->
          Logger.warning("Generated user failed validation", %{
            user_attrs: user_attrs,
            validation_error: reason
          })

          nil
      end
    rescue
      error ->
        Logger.warning("Exception during user generation", %{
          error: error,
          stacktrace: __STACKTRACE__
        })

        nil
    end
  end

  @doc """
  Generates a random birthdate within the configured range (1970-2024).

  ## Returns
  - Date struct within the valid range
  """
  def generate_random_birthdate do
    {start_date, end_date} = Config.birth_date_range()

    start_days = Date.to_gregorian_days(start_date)
    end_days = Date.to_gregorian_days(end_date)

    random_days = Enum.random(start_days..end_days)
    Date.from_gregorian_days(random_days)
  end

  # Private functions

  defp generate_users_with_retry(names_data, count) do
    # Generate users with retry logic for failed generations
    # Allow up to 2x attempts to account for failures
    max_attempts = count * 2

    {users, failed_count} =
      1..max_attempts
      |> Enum.reduce_while({[], 0}, fn _, {users, failed} ->
        if length(users) >= count do
          {:halt, {users, failed}}
        else
          case generate_random_user(names_data) do
            nil -> {:cont, {users, failed + 1}}
            user -> {:cont, {[user | users], failed}}
          end
        end
      end)

    {Enum.take(Enum.reverse(users), count), failed_count}
  end

  defp validate_names_data(names_data) do
    required_keys = [:male_names, :female_names, :male_surnames, :female_surnames]

    case Enum.all?(required_keys, &Map.has_key?(names_data, &1)) do
      true ->
        case Enum.all?(required_keys, fn key ->
               list = Map.get(names_data, key)
               is_list(list) and length(list) > 0
             end) do
          true -> :ok
          false -> {:error, :empty_name_lists}
        end

      false ->
        {:error, :missing_required_keys}
    end
  end

  defp select_random_gender do
    Enum.random([:male, :female])
  end

  defp select_random_name(names_data, :male) do
    Enum.random(names_data.male_names)
  end

  defp select_random_name(names_data, :female) do
    Enum.random(names_data.female_names)
  end

  defp select_random_surname(names_data, :male) do
    Enum.random(names_data.male_surnames)
  end

  defp select_random_surname(names_data, :female) do
    Enum.random(names_data.female_surnames)
  end

  defp format_name(name) when is_binary(name) do
    name
    |> String.trim()
    |> String.downcase()
    |> String.capitalize()
    |> handle_polish_characters()
  end

  defp handle_polish_characters(name) do
    # Ensure proper handling of Polish characters in capitalization
    # This handles cases where String.capitalize might not work correctly with Polish diacritics
    case String.length(name) do
      0 ->
        name

      1 ->
        String.upcase(name)

      _ ->
        first_char = String.at(name, 0) |> String.upcase()
        rest = String.slice(name, 1..-1//1) |> String.downcase()
        first_char <> rest
    end
  end

  defp validate_user_attrs(attrs) do
    # Validate using the actual User changeset to ensure compatibility
    case validate_with_changeset(attrs) do
      :ok ->
        # Also run our basic validations as a backup
        with :ok <- validate_required_fields(attrs),
             :ok <- validate_field_types(attrs),
             :ok <- validate_field_lengths(attrs),
             :ok <- validate_gender(attrs) do
          :ok
        end

      error ->
        error
    end
  end

  defp validate_with_changeset(attrs) do
    # Test the attributes against the actual User changeset
    changeset = Api.Accounts.User.changeset(%Api.Accounts.User{}, attrs)

    case changeset.valid? do
      true -> :ok
      false -> {:error, {:changeset_validation_failed, changeset.errors}}
    end
  end

  defp validate_required_fields(attrs) do
    required_fields = [:first_name, :last_name, :birthdate, :gender]

    case Enum.all?(required_fields, &Map.has_key?(attrs, &1)) do
      true ->
        case Enum.all?(required_fields, fn field ->
               value = Map.get(attrs, field)
               value != nil and value != ""
             end) do
          true -> :ok
          false -> {:error, :blank_required_fields}
        end

      false ->
        {:error, :missing_required_fields}
    end
  end

  defp validate_field_types(%{
         first_name: first_name,
         last_name: last_name,
         birthdate: birthdate,
         gender: gender
       }) do
    cond do
      not is_binary(first_name) -> {:error, :invalid_first_name_type}
      not is_binary(last_name) -> {:error, :invalid_last_name_type}
      not match?(%Date{}, birthdate) -> {:error, :invalid_birthdate_type}
      gender not in [:male, :female] -> {:error, :invalid_gender_type}
      true -> :ok
    end
  end

  defp validate_field_lengths(%{first_name: first_name, last_name: last_name}) do
    cond do
      String.length(first_name) == 0 -> {:error, :empty_first_name}
      String.length(first_name) > 255 -> {:error, :first_name_too_long}
      String.length(last_name) == 0 -> {:error, :empty_last_name}
      String.length(last_name) > 255 -> {:error, :last_name_too_long}
      true -> :ok
    end
  end

  defp validate_gender(%{gender: gender}) do
    case gender in [:male, :female] do
      true -> :ok
      false -> {:error, :invalid_gender_value}
    end
  end

  defp summarize_names_data(names_data) when is_map(names_data) do
    %{
      male_names_count: length(Map.get(names_data, :male_names, [])),
      female_names_count: length(Map.get(names_data, :female_names, [])),
      male_surnames_count: length(Map.get(names_data, :male_surnames, [])),
      female_surnames_count: length(Map.get(names_data, :female_surnames, [])),
      has_all_required_keys:
        Enum.all?(
          [:male_names, :female_names, :male_surnames, :female_surnames],
          &Map.has_key?(names_data, &1)
        )
    }
  end

  defp summarize_names_data(_), do: %{error: "invalid_names_data_structure"}
end
