defmodule BankingApiWeb.WithdrawControllerTest do
  @moduledoc false
  use BankingApiWeb.ConnCase

  import BankingApi.CommonFixtures
  alias BankingApi.Accounts
  alias BankingApi.Accounts.Guardian

  setup %{conn: conn} do
    user =
      user_fixture(%{profile: :user, email: "withdraw_tests_user@email.com", balance: 100_000})

    {:ok, token, _} = Guardian.encode_and_sign(user)

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> put_req_header("accept", "application/json")
      |> assign(:user_id, user.id)

    {:ok, conn: conn}
  end

  describe "withdraw" do
    test "attempts to execute a withdraw with a negative amount and returns the changeset error",
         %{conn: conn} do
      conn =
        post(conn, Routes.withdraw_path(conn, :create),
          withdraw: %{idempotency_key: "invalid request", amount: -1000}
        )

      assert %{"errors" => %{"amount" => ["must be greater than 0"]}} = json_response(conn, 422)
    end

    test "attempts to execute an invalid withdraw returns the changeset error, then using the same idempotency key with valid withdraw returns success, then the same request returns error ",
         %{conn: conn} do
      user = Accounts.get_user!(conn.assigns.user_id)

      conn =
        post(conn, Routes.withdraw_path(conn, :create),
          withdraw: %{idempotency_key: "idempotency requests", amount: -1000}
        )

      conn =
        post(conn, Routes.withdraw_path(conn, :create),
          withdraw: %{idempotency_key: "idempotency requests", amount: 1000}
        )

      assert %{"user" => updated_user, "withdraw" => withdraw} = json_response(conn, 201)

      assert updated_user["id"] == user.id
      assert updated_user["balance"] == user.balance - 1000
      assert withdraw["amount"] == 1000
      refute is_nil(withdraw["id"])

      conn =
        post(conn, Routes.withdraw_path(conn, :create),
          withdraw: %{idempotency_key: "idempotency requests", amount: 1000}
        )

      assert %{"message" => "transaction_already_finished", "withdraw" => last_withdraw} =
               json_response(conn, 400)

      assert last_withdraw == withdraw
    end
  end
end
