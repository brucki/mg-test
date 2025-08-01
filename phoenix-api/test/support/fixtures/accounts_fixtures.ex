defmodule Api.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Api.Accounts` context.
  """

  @doc """
  Generate a user.
  """
  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        first_name: "Jan",
        last_name: "Kowalski",
        gender: :male,
        birthdate: ~D[1990-01-15]
      })
      |> Api.Accounts.create_user()

    user
  end
end
