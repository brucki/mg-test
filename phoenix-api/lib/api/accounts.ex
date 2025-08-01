defmodule Api.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Api.Repo

  alias Api.Accounts.User

  @doc """
  Returns the list of users with optional filtering, sorting, and pagination.

  ## Parameters
    - first_name: Filter by first name (partial match, case insensitive)
    - last_name: Filter by last name (partial match, case insensitive)
    - gender: Filter by gender ("male", "female", or nil for all)
    - birthdate_from: Filter by minimum birthdate (inclusive)
    - birthdate_to: Filter by maximum birthdate (inclusive)
    - sort_by: The field to sort by (e.g., "id", "first_name", "last_name", "gender", "birthdate")
    - sort_order: The sort order ("asc" or "desc")
    - page: Page number (default: 1)
    - per_page: Number of items per page (default: 10)

  ## Examples

      # Get all users
      iex> list_users()
      %{entries: [%User{}, ...], total_entries: 10, page_number: 1, page_size: 10}

      # Filter by first name
      iex> list_users(first_name: "John")

      # Filter by gender
      iex> list_users(gender: "male")

      # Filter by birthdate range
      iex> list_users(birthdate_from: ~D[2000-01-01], birthdate_to: ~D[2010-12-31])

      # Combine filters, sorting and pagination
      iex> list_users(
        first_name: "John",
        gender: "male",
        sort_by: "last_name",
        sort_order: "asc",
        page: 2,
        per_page: 5
      )
  """
  def list_users(opts \\ []) do
    # Parse parameters with defaults
    first_name = opts[:first_name]
    last_name = opts[:last_name]
    gender = opts[:gender]
    birthdate_from = opts[:birthdate_from]
    birthdate_to = opts[:birthdate_to]
    sort_by = opts[:sort_by] || "id"
    sort_order = opts[:sort_order] || "asc"
    page = max(opts[:page] || 1, 1)
    # Cap at 100 items per page
    per_page = max(min(opts[:per_page] || 10, 100), 1)

    # Base query
    query = from(u in User)

    # Apply filters
    query =
      if first_name && first_name != "" do
        search_term = "%#{String.downcase(first_name)}%"
        from(u in query, where: ilike(fragment("lower(?)", u.first_name), ^search_term))
      else
        query
      end

    query =
      if last_name && last_name != "" do
        search_term = "%#{String.downcase(last_name)}%"
        from(u in query, where: ilike(fragment("lower(?)", u.last_name), ^search_term))
      else
        query
      end

    query =
      case gender do
        "male" -> from(u in query, where: u.gender == ^:male)
        "female" -> from(u in query, where: u.gender == ^:female)
        _ -> query
      end

    query =
      if birthdate_from do
        from(u in query, where: u.birthdate >= ^birthdate_from)
      else
        query
      end

    query =
      if birthdate_to do
        from(u in query, where: u.birthdate <= ^birthdate_to)
      else
        query
      end

    # Get total count before pagination
    total_entries = Repo.aggregate(query, :count, :id)

    # Convert sort_by to atom and validate it's a valid field
    field = String.to_existing_atom(sort_by)

    # Build order_by clause based on sort_order
    order_by_clause =
      case sort_order do
        "desc" -> [desc: field]
        _ -> [asc: field]
      end

    # Apply sorting and pagination
    query =
      from(u in query,
        order_by: ^order_by_clause,
        limit: ^per_page,
        offset: ^((page - 1) * per_page)
      )

    %{
      entries: Repo.all(query),
      total_entries: total_entries,
      page_number: page,
      page_size: per_page,
      total_pages: ceil(total_entries / per_page)
    }
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Gets a single user.

  Returns `nil` if the User does not exist.

  ## Examples

      iex> get_user(123)
      %User{}

      iex> get_user(456)
      nil

  """
  def get_user(id), do: Repo.get(User, id)

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end
end
