defmodule Api.DataImport.UserGeneratorTest do
  use Api.DataCase

  alias Api.DataImport.UserGenerator
  alias Api.Accounts.User

  describe "generate_users/2" do
    setup do
      names_data = %{
        male_names: ["ADAM", "ANDRZEJ", "PIOTR", "TOMASZ", "KRZYSZTOF"],
        female_names: ["ANNA", "MARIA", "KATARZYNA", "MAŁGORZATA", "AGNIESZKA"],
        male_surnames: ["NOWAK", "KOWALSKI", "WIŚNIEWSKI", "WÓJCIK", "KOWALCZYK"],
        female_surnames: ["NOWAK", "KOWALSKA", "WIŚNIEWSKA", "WÓJCIK", "KOWALCZYK"]
      }

      {:ok, names_data: names_data}
    end

    test "generates the specified number of users", %{names_data: names_data} do
      assert {:ok, users} = UserGenerator.generate_users(names_data, 5)
      assert length(users) == 5
    end

    test "generates default number of users when count not specified", %{names_data: names_data} do
      assert {:ok, users} = UserGenerator.generate_users(names_data)
      assert length(users) == 100
    end

    test "generates users with all required fields", %{names_data: names_data} do
      assert {:ok, users} = UserGenerator.generate_users(names_data, 3)

      for user <- users do
        assert Map.has_key?(user, :first_name)
        assert Map.has_key?(user, :last_name)
        assert Map.has_key?(user, :gender)
        assert Map.has_key?(user, :birthdate)

        assert is_binary(user.first_name)
        assert is_binary(user.last_name)
        assert user.gender in [:male, :female]
        assert match?(%Date{}, user.birthdate)
      end
    end

    test "generates users with gender-consistent names", %{names_data: names_data} do
      assert {:ok, users} = UserGenerator.generate_users(names_data, 20)

      for user <- users do
        case user.gender do
          :male ->
            assert user.first_name in ["Adam", "Andrzej", "Piotr", "Tomasz", "Krzysztof"]
            assert user.last_name in ["Nowak", "Kowalski", "Wiśniewski", "Wójcik", "Kowalczyk"]

          :female ->
            assert user.first_name in ["Anna", "Maria", "Katarzyna", "Małgorzata", "Agnieszka"]
            assert user.last_name in ["Nowak", "Kowalska", "Wiśniewska", "Wójcik", "Kowalczyk"]
        end
      end
    end

    test "generates users with properly formatted names", %{names_data: names_data} do
      assert {:ok, users} = UserGenerator.generate_users(names_data, 5)

      for user <- users do
        # Names should be properly capitalized (first letter uppercase, rest lowercase)
        assert user.first_name =~ ~r/^[A-ZĄĆĘŁŃÓŚŹŻ][a-ząćęłńóśźż]*$/u
        assert user.last_name =~ ~r/^[A-ZĄĆĘŁŃÓŚŹŻ][a-ząćęłńóśźż]*$/u
      end
    end

    test "generates users with birthdates in valid range", %{names_data: names_data} do
      assert {:ok, users} = UserGenerator.generate_users(names_data, 10)

      for user <- users do
        assert Date.compare(user.birthdate, ~D[1970-01-01]) in [:gt, :eq]
        assert Date.compare(user.birthdate, ~D[2024-12-31]) in [:lt, :eq]
      end
    end

    test "generated users pass User changeset validation", %{names_data: names_data} do
      assert {:ok, users} = UserGenerator.generate_users(names_data, 10)

      for user_attrs <- users do
        changeset = User.changeset(%User{}, user_attrs)
        assert changeset.valid?, "User should be valid: #{inspect(changeset.errors)}"
      end
    end

    test "returns error when names_data is missing required keys" do
      incomplete_data = %{male_names: ["ADAM"], female_names: ["ANNA"]}

      assert {:error, :missing_required_keys} = UserGenerator.generate_users(incomplete_data, 1)
    end

    test "returns error when name lists are empty" do
      empty_data = %{
        male_names: [],
        female_names: ["ANNA"],
        male_surnames: ["NOWAK"],
        female_surnames: ["NOWAK"]
      }

      assert {:error, :empty_name_lists} = UserGenerator.generate_users(empty_data, 1)
    end
  end

  describe "generate_random_user/1" do
    setup do
      names_data = %{
        male_names: ["ADAM", "PIOTR"],
        female_names: ["ANNA", "MARIA"],
        male_surnames: ["NOWAK", "KOWALSKI"],
        female_surnames: ["NOWAK", "KOWALSKA"]
      }

      {:ok, names_data: names_data}
    end

    test "generates a single user with all required fields", %{names_data: names_data} do
      user = UserGenerator.generate_random_user(names_data)

      assert is_map(user)
      assert Map.has_key?(user, :first_name)
      assert Map.has_key?(user, :last_name)
      assert Map.has_key?(user, :gender)
      assert Map.has_key?(user, :birthdate)
    end

    test "generates user with gender-consistent names", %{names_data: names_data} do
      # Generate multiple users to test both genders
      users = Enum.map(1..10, fn _ -> UserGenerator.generate_random_user(names_data) end)

      for user <- users do
        case user.gender do
          :male ->
            assert user.first_name in ["Adam", "Piotr"]
            assert user.last_name in ["Nowak", "Kowalski"]

          :female ->
            assert user.first_name in ["Anna", "Maria"]
            assert user.last_name in ["Nowak", "Kowalska"]
        end
      end
    end
  end

  describe "generate_random_birthdate/0" do
    test "generates dates within the valid range" do
      # Test multiple dates to ensure they're all in range
      dates = Enum.map(1..20, fn _ -> UserGenerator.generate_random_birthdate() end)

      for date <- dates do
        assert match?(%Date{}, date)
        assert Date.compare(date, ~D[1970-01-01]) in [:gt, :eq]
        assert Date.compare(date, ~D[2024-12-31]) in [:lt, :eq]
      end
    end

    test "generates different dates (randomness check)" do
      dates = Enum.map(1..50, fn _ -> UserGenerator.generate_random_birthdate() end)
      unique_dates = Enum.uniq(dates)

      # Should have some variety in dates (not all the same)
      assert length(unique_dates) > 1
    end
  end

  describe "validate_users_batch/1" do
    setup do
      names_data = %{
        male_names: ["ADAM", "PIOTR"],
        female_names: ["ANNA", "MARIA"],
        male_surnames: ["NOWAK", "KOWALSKI"],
        female_surnames: ["NOWAK", "KOWALSKA"]
      }

      {:ok, names_data: names_data}
    end

    test "validates a batch of valid users", %{names_data: names_data} do
      assert {:ok, users} = UserGenerator.generate_users(names_data, 5)
      assert {:ok, valid_users} = UserGenerator.validate_users_batch(users)
      assert length(valid_users) == 5
    end

    test "handles mixed valid and invalid users" do
      valid_user = %{
        first_name: "Adam",
        last_name: "Nowak",
        gender: :male,
        birthdate: ~D[1990-01-01]
      }

      invalid_user = %{
        # Invalid - empty string
        first_name: "",
        last_name: "Nowak",
        gender: :male,
        birthdate: ~D[1990-01-01]
      }

      users = [valid_user, invalid_user]

      assert {:error, {valid_users, errors}} = UserGenerator.validate_users_batch(users)
      assert length(valid_users) == 1
      assert length(errors) == 1

      {index, _user_attrs, _reason} = hd(errors)
      # Second user (0-indexed)
      assert index == 1
    end

    test "returns all valid when all users are valid" do
      users = [
        %{first_name: "Adam", last_name: "Nowak", gender: :male, birthdate: ~D[1990-01-01]},
        %{first_name: "Anna", last_name: "Kowalska", gender: :female, birthdate: ~D[1985-05-15]}
      ]

      assert {:ok, valid_users} = UserGenerator.validate_users_batch(users)
      assert length(valid_users) == 2
    end

    test "handles empty list" do
      assert {:ok, []} = UserGenerator.validate_users_batch([])
    end
  end

  describe "edge cases and error handling" do
    test "handles Polish characters correctly in name formatting" do
      names_data = %{
        male_names: ["ŁUKASZ", "MICHAŁ", "PAWEŁ"],
        female_names: ["MAŁGORZATA", "AGNIESZKA", "ŻANETA"],
        male_surnames: ["WÓJCIK", "ZIELIŃSKI", "SZYMAŃSKI"],
        female_surnames: ["WÓJCIK", "ZIELIŃSKA", "SZYMAŃSKA"]
      }

      assert {:ok, users} = UserGenerator.generate_users(names_data, 10)

      for user <- users do
        # Check that Polish characters are properly handled in capitalization
        assert user.first_name =~ ~r/^[A-ZĄĆĘŁŃÓŚŹŻ][a-ząćęłńóśźż]*$/u
        assert user.last_name =~ ~r/^[A-ZĄĆĘŁŃÓŚŹŻ][a-ząćęłńóśźż]*$/u
      end
    end

    test "generates users with consistent gender distribution over large sample" do
      names_data = %{
        male_names: ["ADAM", "PIOTR", "TOMASZ"],
        female_names: ["ANNA", "MARIA", "KATARZYNA"],
        male_surnames: ["NOWAK", "KOWALSKI", "WIŚNIEWSKI"],
        female_surnames: ["NOWAK", "KOWALSKA", "WIŚNIEWSKA"]
      }

      assert {:ok, users} = UserGenerator.generate_users(names_data, 100)

      male_count = Enum.count(users, &(&1.gender == :male))
      female_count = Enum.count(users, &(&1.gender == :female))

      # Should have both genders represented (not all one gender)
      assert male_count > 0
      assert female_count > 0
      assert male_count + female_count == 100
    end

    test "handles single name/surname lists" do
      names_data = %{
        male_names: ["ADAM"],
        female_names: ["ANNA"],
        male_surnames: ["NOWAK"],
        female_surnames: ["KOWALSKA"]
      }

      assert {:ok, users} = UserGenerator.generate_users(names_data, 5)
      assert length(users) == 5

      for user <- users do
        case user.gender do
          :male ->
            assert user.first_name == "Adam"
            assert user.last_name == "Nowak"

          :female ->
            assert user.first_name == "Anna"
            assert user.last_name == "Kowalska"
        end
      end
    end

    test "birthdate generation covers full range" do
      # Generate many birthdates to test range coverage
      birthdates = Enum.map(1..1000, fn _ -> UserGenerator.generate_random_birthdate() end)

      # Check that we get dates from different years
      years = Enum.map(birthdates, & &1.year) |> Enum.uniq() |> Enum.sort()

      # Should have variety in years (at least 10 different years)
      assert length(years) >= 10
      assert Enum.min(years) >= 1970
      assert Enum.max(years) <= 2024
    end

    test "handles very large user generation requests" do
      names_data = %{
        male_names: ["ADAM", "PIOTR"],
        female_names: ["ANNA", "MARIA"],
        male_surnames: ["NOWAK", "KOWALSKI"],
        female_surnames: ["NOWAK", "KOWALSKA"]
      }

      # Test generating a large number of users
      assert {:ok, users} = UserGenerator.generate_users(names_data, 500)
      assert length(users) == 500

      # All should be valid
      for user <- users do
        assert is_binary(user.first_name)
        assert is_binary(user.last_name)
        assert user.gender in [:male, :female]
        assert match?(%Date{}, user.birthdate)
      end
    end

    test "returns error when no valid users can be generated" do
      # This is hard to test directly since our generator is robust,
      # but we can test the error path by providing invalid data
      invalid_names_data = %{
        male_names: [],
        female_names: [],
        male_surnames: [],
        female_surnames: []
      }

      assert {:error, :empty_name_lists} = UserGenerator.generate_users(invalid_names_data, 1)
    end
  end
end
