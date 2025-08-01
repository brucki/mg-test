defmodule ApiWeb.UserController do
  use ApiWeb, :controller

  alias Api.Accounts

  action_fallback(ApiWeb.FallbackController)
  
  @doc """
  Handle CORS preflight requests for /users and /users/:id
  """
  def options(conn, _params) do
    conn
    |> put_resp_header("access-control-allow-methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
    |> put_resp_header("access-control-allow-headers", "content-type, accept, authorization")
    |> put_resp_header("access-control-max-age", "3600")
    |> send_resp(204, "")
  end

  @doc """
  GET /users

  Lists all users with optional filtering, sorting, and pagination.

  ## Query Parameters
    - first_name: Filter by first name (partial match, case insensitive)
    - last_name: Filter by last name (partial match, case insensitive)
    - gender: Filter by gender ("male" or "female")
    - birthdate_from: Filter by minimum birthdate (YYYY-MM-DD)
    - birthdate_to: Filter by maximum birthdate (YYYY-MM-DD)
    - page: Page number (default: 1)
    - per_page: Number of items per page (default: 10, max: 100)
    - sort_by: Field to sort by (default: "id")
    - sort_order: Sort order ("asc" or "desc", default: "asc")
  """
  def index(conn, params) do
    # Parse pagination parameters with defaults and validation
    page = String.to_integer(params["page"] || "1") |> max(1)
    per_page = String.to_integer(params["per_page"] || "10") |> min(100) |> max(1)
    
    # Parse filter parameters
    first_name = params["first_name"]
    last_name = params["last_name"]
    gender = params["gender"]
    
    # Parse and validate date parameters
    birthdate_from = parse_date_param(params["birthdate_from"])
    birthdate_to = parse_date_param(params["birthdate_to"])
    
    # Parse sort parameters
    sort_by = params["sort_by"] || "id"
    sort_order = if params["sort_order"] in ["asc", "desc"], do: params["sort_order"], else: "asc"
    
    # Call the context function with all parameters
    %{
      entries: users,
      total_entries: total_entries,
      page_number: current_page,
      page_size: page_size,
      total_pages: total_pages
    } = Accounts.list_users([
      first_name: first_name,
      last_name: last_name,
      gender: gender,
      birthdate_from: birthdate_from,
      birthdate_to: birthdate_to,
      sort_by: sort_by,
      sort_order: sort_order,
      page: page,
      per_page: per_page
    ])

    # Set response headers with pagination info
    conn = conn
    |> put_resp_header("x-total-count", to_string(total_entries))
    |> put_resp_header("x-total-pages", to_string(total_pages))
    |> put_resp_header("x-per-page", to_string(page_size))
    |> put_resp_header("x-current-page", to_string(current_page))
    
    # Render the response
    render(conn, :index, %{
      users: users,
      total_count: total_entries,
      total_pages: total_pages,
      current_page: current_page,
      per_page: page_size,
      filters: %{
        first_name: first_name,
        last_name: last_name,
        gender: gender,
        birthdate_from: birthdate_from,
        birthdate_to: birthdate_to,
        sort_by: sort_by,
        sort_order: sort_order
      }
    })
  end
  
  # Helper function to parse date parameters
  defp parse_date_param(nil), do: nil
  defp parse_date_param(""), do: nil
  defp parse_date_param(date_str) do
    case Date.from_iso8601(date_str) do
      {:ok, date} -> date
      _ -> nil
    end
  end

  @doc """
  GET /users/:id

  Shows a specific user.
  """
  def show(conn, %{"id" => id}) do
    case Accounts.get_user(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "User not found"})

      user ->
        render(conn, :show, user: user)
    end
  end

  @doc """
  POST /users

  Creates a new user.

  Expected JSON body:
  {
    "user": {
      "first_name": "Jan",
      "last_name": "Kowalski",
      "gender": "male",
      "birthdate": "1990-01-15"
    }
  }
  """
  def create(conn, %{"user" => user_params}) do
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", ~p"/users/#{user}")
        |> render(:show, user: user)

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:error, changeset: changeset)
    end
  end

  def create(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Missing 'user' parameter in request body"})
  end

  @doc """
  PUT /users/:id

  Updates an existing user.

  Expected JSON body:
  {
    "user": {
      "first_name": "Jan",
      "last_name": "Kowalski",
      "gender": "male",
      "birthdate": "1990-01-15"
    }
  }
  """
  def update(conn, %{"id" => id, "user" => user_params}) do
    case Accounts.get_user(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "User not found"})

      user ->
        case Accounts.update_user(user, user_params) do
          {:ok, user} ->
            render(conn, :show, user: user)

          {:error, %Ecto.Changeset{} = changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> render(:error, changeset: changeset)
        end
    end
  end

  def update(conn, %{"id" => _id}) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Missing 'user' parameter in request body"})
  end

  @doc """
  DELETE /users/:id

  Deletes a user.
  """
  def delete(conn, %{"id" => id}) do
    case Accounts.get_user(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "User not found"})

      user ->
        case Accounts.delete_user(user) do
          {:ok, _user} ->
            send_resp(conn, :no_content, "")

          {:error, %Ecto.Changeset{} = changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> render(:error, changeset: changeset)
        end
    end
  end
end
