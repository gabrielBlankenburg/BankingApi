defmodule BankingApiWeb.Plugs.AuthorizeProfileTest do
  @moduledoc false
  use BankingApiWeb.ConnCase
  import BankingApi.CommonFixtures
  alias BankingApiWeb.Plugs.AuthorizeProfile
  alias BankingApi.Accounts.Guardian

  setup %{conn: conn} do
    conn =
      conn
      |> put_req_header("accept", "application/json")

    {:ok, conn: conn}
  end

  describe "Admin Profile" do
    setup %{conn: conn} do
      user = user_fixture(%{profile: :admin, email: "admin@user.com"})
      {:ok, token, _} = Guardian.encode_and_sign(user)

      conn = put_req_header(conn, "authorization", "Bearer #{token}")
      %{conn: conn, user: user}
    end

    test "is allowed on routes for admin profiles", %{conn: conn, user: user} do
      assert conn
             |> bypass_through(BankingApiWeb.Router)
             |> get("/api/admin/users")
             |> Map.get(:assigns)
             |> Map.get(:user_id) == user.id
    end

    test "is allowed on routes for user profiles", %{conn: conn, user: user} do
      assert conn
             |> bypass_through(BankingApiWeb.Router)
             |> post("/api/withdrawal")
             |> Map.get(:assigns)
             |> Map.get(:user_id) == user.id
    end
  end

  describe "User Profile" do
    setup %{conn: conn} do
      user = user_fixture(%{profile: :user, email: "user@user.com"})
      {:ok, token, _} = Guardian.encode_and_sign(user)

      conn = put_req_header(conn, "authorization", "Bearer #{token}")
      %{conn: conn, user: user}
    end

    test "is not allowed on routes for admin profiles", %{conn: conn, user: user} do
      conn =
        conn
        |> bypass_through(BankingApiWeb.Router)
        |> get("/api/admin/users")

      assert conn.halted
      assert conn.status == 403
      assert conn.resp_body == Jason.encode!(%{"message" => "unauthorized"})
    end

    test "is allowed on routes for user profiles", %{conn: conn, user: user} do
      assert conn
             |> bypass_through(BankingApiWeb.Router)
             |> post("/api/withdrawal")
             |> Map.get(:assigns)
             |> Map.get(:user_id) == user.id
    end
  end
end
