defmodule BankingApiWeb.UserControllerTest do
  @moduledoc false
  use BankingApiWeb.ConnCase
  import BankingApi.CommonFixtures

  alias BankingApi.Accounts.{User, Guardian}

  @create_attrs %{
    balance: 42,
    name: "Some User",
    email: "test@email.com",
    password: "some password_hash",
    profile: :user
  }
  @update_attrs %{
    balance: 43,
    name: "Some User",
    email: "update@email.com",
    password: "some updated password_hash",
    profile: :user
  }
  @invalid_attrs %{balance: nil, email: nil, password_hash: nil, profile: nil}

  setup %{conn: conn} do
    admin_user = user_fixture(%{profile: :admin, email: "admin@user.com", password: "admin123"})
    {:ok, token, _} = Guardian.encode_and_sign(admin_user)

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> put_req_header("accept", "application/json")

    {:ok, conn: conn}
  end

  describe "index" do
    test "lists all users", %{conn: conn} do
      conn = get(conn, Routes.user_path(conn, :index))
      # It's no longer empty since we have the admin user setted for the conn context
      assert conn
             |> json_response(200)
             |> Map.get("data")
             |> is_list()
    end
  end

  describe "create user" do
    test "renders user when data is valid", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :create), user: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.user_path(conn, :show, id))

      assert %{
               "id" => ^id,
               "balance" => 42,
               "email" => "test@email.com",
               "profile" => "user"
             } = json_response(conn, 200)["data"]

      assert is_nil(json_response(conn, 200)["data"]["password"])
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :create), user: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update user" do
    setup [:create_user]

    test "renders user when data is valid", %{conn: conn, user: %User{id: id} = user} do
      conn = put(conn, Routes.user_path(conn, :update, user), user: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]
      conn = get(conn, Routes.user_path(conn, :show, id))

      assert %{
               "id" => ^id,
               "balance" => 43,
               "email" => "update@email.com",
               "profile" => "user"
             } = json_response(conn, 200)["data"]

      assert is_nil(json_response(conn, 200)["data"]["password"])
    end

    test "renders errors when data is invalid", %{conn: conn, user: user} do
      conn = put(conn, Routes.user_path(conn, :update, user), user: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete user" do
    setup [:create_user]

    test "deletes chosen user", %{conn: conn, user: user} do
      conn = delete(conn, Routes.user_path(conn, :delete, user))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.user_path(conn, :show, user))
      end
    end
  end

  defp create_user(_) do
    user = user_fixture()
    %{user: user}
  end
end
