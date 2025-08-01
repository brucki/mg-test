defmodule ApiWeb.UserJSON do
  alias Api.Accounts.User

  @doc """
  Renders a list of users.
  """
  def index(%{users: users, total_count: total_count}) do
    %{
      data: for(user <- users, do: data(user)),
      meta: %{
        total_count: total_count,
        count: length(users)
      }
    }
  end

  @doc """
  Renders a single user.
  """
  def show(%{user: user}) do
    %{data: data(user)}
  end

  @doc """
  Renders validation errors.
  """
  def error(%{changeset: changeset}) do
    %{
      error: "Validation failed",
      details: translate_errors(changeset)
    }
  end

  defp data(%User{} = user) do
    %{
      id: user.id,
      first_name: user.first_name,
      last_name: user.last_name,
      gender: user.gender,
      birthdate: user.birthdate,
      inserted_at: user.inserted_at,
      updated_at: user.updated_at
    }
  end

  defp translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
