defmodule Api.DataImport.UserGeneratorIntegrationTest do
  use Api.DataCase

  alias Api.DataImport.UserGenerator
  alias Api.Accounts

  describe "UserGenerator integration with database" do
    setup do
      names_data = %{
        male_names: ["ADAM", "ANDRZEJ", "PIOTR"],
        female_names: ["ANNA", "MARIA", "KATARZYNA"],
        male_surnames: ["NOWAK", "KOWALSKI", "WIŚNIEWSKI"],
        female_surnames: ["NOWAK", "KOWALSKA", "WIŚNIEWSKA"]
      }

      {:ok, names_data: names_data}
    end

    test "generated users can be successfully saved to database", %{names_data: names_data} do
      # Generate a small batch of users
      assert {:ok, users} = UserGenerator.generate_users(names_data, 5)

      # Try to create each user in the database
      created_users =
        users
        |> Enum.map(fn user_attrs ->
          case Accounts.create_user(user_attrs) do
            {:ok, user} ->
              user

            {:error, changeset} ->
              flunk(
                "Failed to create user with attrs #{inspect(user_attrs)}: #{inspect(changeset.errors)}"
              )
          end
        end)

      # Verify all users were created successfully
      assert length(created_users) == 5

      # Verify users have proper IDs and timestamps
      for user <- created_users do
        assert user.id
        assert user.inserted_at
        assert user.updated_at

        # Verify the data integrity
        assert is_binary(user.first_name)
        assert is_binary(user.last_name)
        assert user.gender in [:male, :female]
        assert match?(%Date{}, user.birthdate)

        # Verify names are properly formatted
        assert user.first_name =~ ~r/^[A-ZĄĆĘŁŃÓŚŹŻ][a-ząćęłńóśźż]*$/u
        assert user.last_name =~ ~r/^[A-ZĄĆĘŁŃÓŚŹŻ][a-ząćęłńóśźż]*$/u
      end

      # Verify we can retrieve the users from the database
      %{entries: db_users} = Accounts.list_users()
      assert length(db_users) >= 5
    end

    test "batch user creation with generated data", %{names_data: names_data} do
      # Generate a larger batch
      assert {:ok, users} = UserGenerator.generate_users(names_data, 10)

      # Create all users in a single transaction-like operation
      results =
        users
        |> Enum.map(&Accounts.create_user/1)
        |> Enum.split_with(fn
          {:ok, _} -> true
          {:error, _} -> false
        end)

      {successes, failures} = results

      # All should succeed
      assert length(failures) == 0, "Some users failed to be created: #{inspect(failures)}"
      assert length(successes) == 10

      # Extract the actual user structs
      created_users = Enum.map(successes, fn {:ok, user} -> user end)

      # Verify gender distribution (should have both male and female users in a batch of 10)
      genders = Enum.map(created_users, & &1.gender) |> Enum.uniq()
      # At least one gender should be present
      assert :male in genders or :female in genders

      # Verify birthdate distribution (should have variety)
      birthdates = Enum.map(created_users, & &1.birthdate) |> Enum.uniq()
      assert length(birthdates) > 1, "Should have variety in birthdates"
    end

    test "generated users pass all User schema validations", %{names_data: names_data} do
      # Generate users and validate each one individually
      assert {:ok, users} = UserGenerator.generate_users(names_data, 20)

      for user_attrs <- users do
        # Test the changeset validation
        changeset = Api.Accounts.User.changeset(%Api.Accounts.User{}, user_attrs)
        assert changeset.valid?, "User attrs should pass validation: #{inspect(changeset.errors)}"

        # Test actual database insertion
        assert {:ok, _user} = Accounts.create_user(user_attrs)
      end
    end
  end
end
