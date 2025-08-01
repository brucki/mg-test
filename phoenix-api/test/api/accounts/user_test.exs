defmodule Api.Accounts.UserTest do
  use Api.DataCase

  alias Api.Accounts.User

  describe "changeset/2" do
    @valid_attrs %{
      first_name: "John",
      last_name: "Doe",
      birthdate: ~D[1990-01-01],
      gender: :male
    }

    test "valid changeset with all required fields" do
      changeset = User.changeset(%User{}, @valid_attrs)
      assert changeset.valid?
      assert changeset.changes.first_name == "John"
      assert changeset.changes.last_name == "Doe"
      assert changeset.changes.birthdate == ~D[1990-01-01]
      assert changeset.changes.gender == :male
    end

    test "valid changeset with female gender" do
      attrs = Map.put(@valid_attrs, :gender, :female)
      changeset = User.changeset(%User{}, attrs)
      assert changeset.valid?
      assert changeset.changes.gender == :female
    end

    test "invalid changeset when first_name is missing" do
      attrs = Map.delete(@valid_attrs, :first_name)
      changeset = User.changeset(%User{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).first_name
    end

    test "invalid changeset when last_name is missing" do
      attrs = Map.delete(@valid_attrs, :last_name)
      changeset = User.changeset(%User{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).last_name
    end

    test "invalid changeset when birthdate is missing" do
      attrs = Map.delete(@valid_attrs, :birthdate)
      changeset = User.changeset(%User{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).birthdate
    end

    test "invalid changeset when gender is missing" do
      attrs = Map.delete(@valid_attrs, :gender)
      changeset = User.changeset(%User{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).gender
    end

    test "invalid changeset when all required fields are missing" do
      changeset = User.changeset(%User{}, %{})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).first_name
      assert "can't be blank" in errors_on(changeset).last_name
      assert "can't be blank" in errors_on(changeset).birthdate
      assert "can't be blank" in errors_on(changeset).gender
    end

    test "invalid changeset when first_name is empty string" do
      attrs = Map.put(@valid_attrs, :first_name, "")
      changeset = User.changeset(%User{}, attrs)
      refute changeset.valid?
      # Empty string is cast to nil by Ecto, so it triggers required validation
      assert "can't be blank" in errors_on(changeset).first_name
    end

    test "invalid changeset when last_name is empty string" do
      attrs = Map.put(@valid_attrs, :last_name, "")
      changeset = User.changeset(%User{}, attrs)
      refute changeset.valid?
      # Empty string is cast to nil by Ecto, so it triggers required validation
      assert "can't be blank" in errors_on(changeset).last_name
    end

    test "invalid changeset when first_name exceeds maximum length" do
      long_name = String.duplicate("a", 256)
      attrs = Map.put(@valid_attrs, :first_name, long_name)
      changeset = User.changeset(%User{}, attrs)
      refute changeset.valid?
      assert "should be at most 255 character(s)" in errors_on(changeset).first_name
    end

    test "invalid changeset when last_name exceeds maximum length" do
      long_name = String.duplicate("a", 256)
      attrs = Map.put(@valid_attrs, :last_name, long_name)
      changeset = User.changeset(%User{}, attrs)
      refute changeset.valid?
      assert "should be at most 255 character(s)" in errors_on(changeset).last_name
    end

    test "valid changeset when first_name is at maximum length" do
      max_length_name = String.duplicate("a", 255)
      attrs = Map.put(@valid_attrs, :first_name, max_length_name)
      changeset = User.changeset(%User{}, attrs)
      assert changeset.valid?
    end

    test "valid changeset when last_name is at maximum length" do
      max_length_name = String.duplicate("a", 255)
      attrs = Map.put(@valid_attrs, :last_name, max_length_name)
      changeset = User.changeset(%User{}, attrs)
      assert changeset.valid?
    end

    test "invalid changeset when gender is invalid atom" do
      attrs = Map.put(@valid_attrs, :gender, :invalid)
      changeset = User.changeset(%User{}, attrs)
      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).gender
    end

    test "invalid changeset when gender is invalid string" do
      attrs = Map.put(@valid_attrs, :gender, "other")
      changeset = User.changeset(%User{}, attrs)
      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).gender
    end

    test "invalid changeset when gender is nil" do
      attrs = Map.put(@valid_attrs, :gender, nil)
      changeset = User.changeset(%User{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).gender
    end

    test "invalid changeset when birthdate is invalid" do
      attrs = Map.put(@valid_attrs, :birthdate, "invalid-date")
      changeset = User.changeset(%User{}, attrs)
      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).birthdate
    end

    test "invalid changeset when birthdate is nil" do
      attrs = Map.put(@valid_attrs, :birthdate, nil)
      changeset = User.changeset(%User{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).birthdate
    end

    test "valid changeset with different valid birthdates" do
      # Test with different valid date formats
      valid_dates = [
        ~D[1980-12-31],
        # leap year
        ~D[2000-02-29],
        ~D[1995-06-15]
      ]

      for date <- valid_dates do
        attrs = Map.put(@valid_attrs, :birthdate, date)
        changeset = User.changeset(%User{}, attrs)
        assert changeset.valid?, "Date #{date} should be valid"
      end
    end

    test "changeset trims whitespace from string fields" do
      attrs = %{
        first_name: "  John  ",
        last_name: "  Doe  ",
        birthdate: ~D[1990-01-01],
        gender: :male
      }

      changeset = User.changeset(%User{}, attrs)
      assert changeset.valid?
      assert changeset.changes.first_name == "John"
      assert changeset.changes.last_name == "Doe"
    end

    test "changeset handles whitespace-only strings correctly" do
      attrs = %{
        first_name: "   ",
        last_name: "   ",
        birthdate: ~D[1990-01-01],
        gender: :male
      }

      changeset = User.changeset(%User{}, attrs)
      refute changeset.valid?
      # Whitespace-only strings become empty strings after trimming,
      # which are cast to nil by Ecto and trigger required validation
      assert "can't be blank" in errors_on(changeset).first_name
      assert "can't be blank" in errors_on(changeset).last_name
    end
  end
end
