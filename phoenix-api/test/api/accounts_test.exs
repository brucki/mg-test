defmodule Api.AccountsTest do
  use Api.DataCase

  alias Api.Accounts

  describe "users" do
    alias Api.Accounts.User

    @valid_attrs %{
      first_name: "John",
      last_name: "Doe",
      birthdate: ~D[1990-01-01],
      gender: :male
    }
    @update_attrs %{
      first_name: "Jane",
      last_name: "Smith",
      birthdate: ~D[1985-05-15],
      gender: :female
    }
    @invalid_attrs %{first_name: nil, last_name: nil, birthdate: nil, gender: nil}

    def user_fixture(attrs \\ %{}) do
      {:ok, user} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Accounts.create_user()

      user
    end

    test "list_users/0 returns all users" do
      user = user_fixture()
      result = Accounts.list_users()
      assert length(result.entries) == 1
      assert hd(result.entries).id == user.id
    end

    test "list_users/0 returns empty entries when no users exist" do
      result = Accounts.list_users()
      assert result.entries == []
      assert result.total_entries == 0
    end

    test "list_users/0 returns multiple users" do
      user1 = user_fixture(%{first_name: "Alice"})
      user2 = user_fixture(%{first_name: "Bob"})

      result = Accounts.list_users()
      assert length(result.entries) == 2
      assert Enum.any?(result.entries, &(&1.id == user1.id))
      assert Enum.any?(result.entries, &(&1.id == user2.id))
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      assert Accounts.get_user!(user.id) == user
    end

    test "get_user!/1 raises Ecto.NoResultsError when user does not exist" do
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(999) end
    end

    test "get_user/1 returns the user with given id" do
      user = user_fixture()
      assert Accounts.get_user(user.id) == user
    end

    test "get_user/1 returns nil when user does not exist" do
      assert Accounts.get_user(999) == nil
    end

    test "create_user/1 with valid data creates a user" do
      assert {:ok, %User{} = user} = Accounts.create_user(@valid_attrs)
      assert user.first_name == "John"
      assert user.last_name == "Doe"
      assert user.birthdate == ~D[1990-01-01]
      assert user.gender == :male
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_attrs)
    end

    test "create_user/1 with missing first_name returns error changeset" do
      attrs = Map.put(@valid_attrs, :first_name, nil)
      assert {:error, changeset} = Accounts.create_user(attrs)
      assert "can't be blank" in errors_on(changeset).first_name
    end

    test "create_user/1 with missing last_name returns error changeset" do
      attrs = Map.put(@valid_attrs, :last_name, nil)
      assert {:error, changeset} = Accounts.create_user(attrs)
      assert "can't be blank" in errors_on(changeset).last_name
    end

    test "create_user/1 with missing birthdate returns error changeset" do
      attrs = Map.put(@valid_attrs, :birthdate, nil)
      assert {:error, changeset} = Accounts.create_user(attrs)
      assert "can't be blank" in errors_on(changeset).birthdate
    end

    test "create_user/1 with missing gender returns error changeset" do
      attrs = Map.put(@valid_attrs, :gender, nil)
      assert {:error, changeset} = Accounts.create_user(attrs)
      assert "can't be blank" in errors_on(changeset).gender
    end

    test "create_user/1 with invalid gender returns error changeset" do
      attrs = Map.put(@valid_attrs, :gender, :invalid)
      assert {:error, changeset} = Accounts.create_user(attrs)
      assert "is invalid" in errors_on(changeset).gender
    end

    test "create_user/1 with first_name too long returns error changeset" do
      long_name = String.duplicate("a", 256)
      attrs = Map.put(@valid_attrs, :first_name, long_name)
      assert {:error, changeset} = Accounts.create_user(attrs)
      assert "should be at most 255 character(s)" in errors_on(changeset).first_name
    end

    test "create_user/1 with last_name too long returns error changeset" do
      long_name = String.duplicate("a", 256)
      attrs = Map.put(@valid_attrs, :last_name, long_name)
      assert {:error, changeset} = Accounts.create_user(attrs)
      assert "should be at most 255 character(s)" in errors_on(changeset).last_name
    end

    test "create_user/1 trims whitespace from string fields" do
      attrs = %{@valid_attrs | first_name: "  John  ", last_name: "  Doe  "}
      assert {:ok, %User{} = user} = Accounts.create_user(attrs)
      assert user.first_name == "John"
      assert user.last_name == "Doe"
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()
      assert {:ok, %User{} = user} = Accounts.update_user(user, @update_attrs)
      assert user.first_name == "Jane"
      assert user.last_name == "Smith"
      assert user.birthdate == ~D[1985-05-15]
      assert user.gender == :female
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, @invalid_attrs)
      assert user == Accounts.get_user!(user.id)
    end

    test "update_user/2 with invalid gender returns error changeset" do
      user = user_fixture()
      attrs = Map.put(@update_attrs, :gender, :invalid)
      assert {:error, changeset} = Accounts.update_user(user, attrs)
      assert "is invalid" in errors_on(changeset).gender
      assert user == Accounts.get_user!(user.id)
    end

    test "update_user/2 with first_name too long returns error changeset" do
      user = user_fixture()
      long_name = String.duplicate("a", 256)
      attrs = Map.put(@update_attrs, :first_name, long_name)
      assert {:error, changeset} = Accounts.update_user(user, attrs)
      assert "should be at most 255 character(s)" in errors_on(changeset).first_name
      assert user == Accounts.get_user!(user.id)
    end

    test "update_user/2 trims whitespace from string fields" do
      user = user_fixture()
      attrs = %{@update_attrs | first_name: "  Jane  ", last_name: "  Smith  "}
      assert {:ok, %User{} = updated_user} = Accounts.update_user(user, attrs)
      assert updated_user.first_name == "Jane"
      assert updated_user.last_name == "Smith"
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(user.id) end
    end

    test "delete_user/1 raises error when user has already been deleted" do
      user = user_fixture()
      assert {:ok, %User{}} = Accounts.delete_user(user)

      # Attempting to delete again should raise a stale entry error
      assert_raise Ecto.StaleEntryError, fn -> Accounts.delete_user(user) end
    end

    test "change_user/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Accounts.change_user(user)
    end

    test "change_user/1 with attrs returns a user changeset with changes" do
      user = user_fixture()
      changeset = Accounts.change_user(user, @update_attrs)
      assert %Ecto.Changeset{} = changeset
      assert changeset.changes.first_name == "Jane"
      assert changeset.changes.last_name == "Smith"
      assert changeset.changes.birthdate == ~D[1985-05-15]
      assert changeset.changes.gender == :female
    end

    test "change_user/1 with invalid attrs returns invalid changeset" do
      user = user_fixture()
      changeset = Accounts.change_user(user, @invalid_attrs)
      assert %Ecto.Changeset{} = changeset
      refute changeset.valid?
    end

    test "change_user/1 without attrs returns changeset with no changes" do
      user = user_fixture()
      changeset = Accounts.change_user(user)
      assert %Ecto.Changeset{} = changeset
      assert changeset.changes == %{}
    end
  end
end
