defmodule BankingApiWeb.LoginControllerTest do
  @moduledoc false
  use BankingApiWeb.ConnCase
  alias BankingApi.Accounts

  @user_attrs %{
    email: "test@email.com",
    password: "some password_hash"
  }

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(@user_attrs)
      |> Accounts.create_user()

    user
  end

  describe "Register and Login" do
    test "register an user with a unique email returns the user and an authenticated token", %{
      conn: conn
    } do
      conn = post(conn, Routes.login_path(conn, :register), @user_attrs)

      assert %{
               "user" => %{
                 "balance" => 100_000,
                 "email" => "test@email.com",
                 "profile" => "user"
               },
               "token" => token
             } = json_response(conn, 201)

      refute is_nil(token)
    end

    test "register an user with an non unique email returns an error", %{conn: conn} do
      user_fixture(%{email: "duplicate@email.com"})

      conn =
        post(conn, Routes.login_path(conn, :register), %{
          email: "duplicate@email.com",
          password: "some password"
        })

      assert %{
               "errors" => %{
                 "email" => [
                   "has already been taken"
                 ]
               }
             } = json_response(conn, 422)
    end

    test "Login with a valid user returns his token", %{conn: conn} do
      user_fixture(%{email: "another_user@email.com"})

      conn =
        post(conn, Routes.login_path(conn, :login), %{
          email: "another_user@email.com",
          password: "some password_hash"
        })

      result = json_response(conn, 200)
      assert result["token"] != nil
    end

    test "Login with an invalid email or password returns not found", %{conn: conn} do
      conn =
        post(conn, Routes.login_path(conn, :login), %{
          email: "invalid_user@email.com",
          password: "some password"
        })

      assert %{
               "errors" => %{
                 "detail" => "Not Found"
               }
             } = json_response(conn, 404)
    end
  end
end
