defmodule ApiWeb.UserControllerTest do
  use ApiWeb.ConnCase

  import Api.AccountsFixtures

  @create_attrs %{
    first_name: "Jan",
    last_name: "Kowalski",
    gender: :male,
    birthdate: ~D[1990-01-15]
  }
  @update_attrs %{
    first_name: "Anna",
    last_name: "Nowak",
    gender: :female,
    birthdate: ~D[1985-05-20]
  }
  @invalid_attrs %{first_name: nil, last_name: nil, gender: nil, birthdate: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all users", %{conn: conn} do
      conn = get(conn, ~p"/users")
      assert json_response(conn, 200)["data"] == []
    end

    test "lists users with pagination info", %{conn: conn} do
      user = user_fixture()
      conn = get(conn, ~p"/users")

      response = json_response(conn, 200)
      assert length(response["data"]) == 1
      assert response["meta"]["total_count"] == 1
      assert response["meta"]["count"] == 1
      assert List.first(response["data"])["id"] == user.id
    end

    test "includes total count header", %{conn: conn} do
      user_fixture()
      user_fixture()

      conn = get(conn, ~p"/users")

      assert get_resp_header(conn, "x-total-count") == ["2"]
    end
  end

  describe "show" do
    test "shows user when id is valid", %{conn: conn} do
      user = user_fixture()
      conn = get(conn, ~p"/users/#{user}")

      response = json_response(conn, 200)
      assert response["data"]["id"] == user.id
      assert response["data"]["first_name"] == user.first_name
      assert response["data"]["last_name"] == user.last_name
      assert response["data"]["gender"] == to_string(user.gender)
    end

    test "returns 404 when user does not exist", %{conn: conn} do
      conn = get(conn, ~p"/users/999999")
      assert json_response(conn, 404)["error"] == "User not found"
    end
  end

  describe "create" do
    test "creates user when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/users", user: @create_attrs)

      response = json_response(conn, 201)
      assert response["data"]["first_name"] == "Jan"
      assert response["data"]["last_name"] == "Kowalski"
      assert response["data"]["gender"] == "male"
      assert response["data"]["birthdate"] == "1990-01-15"

      # Check location header
      assert get_resp_header(conn, "location") != []
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/users", user: @invalid_attrs)

      response = json_response(conn, 422)
      assert response["error"] == "Validation failed"
      assert response["details"]["first_name"] != nil
      assert response["details"]["last_name"] != nil
      assert response["details"]["gender"] != nil
      assert response["details"]["birthdate"] != nil
    end

    test "returns error when user parameter is missing", %{conn: conn} do
      conn = post(conn, ~p"/users", %{})

      response = json_response(conn, 400)
      assert response["error"] == "Missing 'user' parameter in request body"
    end
  end

  describe "update" do
    setup [:create_user]

    test "updates user when data is valid", %{conn: conn, user: user} do
      conn = put(conn, ~p"/users/#{user}", user: @update_attrs)

      response = json_response(conn, 200)
      assert response["data"]["first_name"] == "Anna"
      assert response["data"]["last_name"] == "Nowak"
      assert response["data"]["gender"] == "female"
      assert response["data"]["birthdate"] == "1985-05-20"
    end

    test "renders errors when data is invalid", %{conn: conn, user: user} do
      conn = put(conn, ~p"/users/#{user}", user: @invalid_attrs)

      response = json_response(conn, 422)
      assert response["error"] == "Validation failed"
    end

    test "returns 404 when user does not exist", %{conn: conn} do
      conn = put(conn, ~p"/users/999999", user: @update_attrs)
      assert json_response(conn, 404)["error"] == "User not found"
    end

    test "returns error when user parameter is missing", %{conn: conn, user: user} do
      conn = put(conn, ~p"/users/#{user}", %{})

      response = json_response(conn, 400)
      assert response["error"] == "Missing 'user' parameter in request body"
    end
  end

  describe "delete" do
    setup [:create_user]

    test "deletes chosen user", %{conn: conn, user: user} do
      conn = delete(conn, ~p"/users/#{user}")
      assert response(conn, 204)

      conn = get(conn, ~p"/users/#{user}")
      assert json_response(conn, 404)["error"] == "User not found"
    end

    test "returns 404 when user does not exist", %{conn: conn} do
      conn = delete(conn, ~p"/users/999999")
      assert json_response(conn, 404)["error"] == "User not found"
    end
  end

  defp create_user(_) do
    user = user_fixture()
    %{user: user}
  end
end
