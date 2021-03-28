defmodule BankingApiWeb.WithdrawalControllerTest do
  @moduledoc false
  use BankingApiWeb.ConnCase

  import BankingApi.CommonFixtures
  alias BankingApi.Accounts
  alias BankingApi.Accounts.Guardian

  setup %{conn: conn} do
    user =
      user_fixture(%{profile: :user, email: "withdrawal_tests_user@email.com", balance: 100_000})

    {:ok, token, _} = Guardian.encode_and_sign(user)

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> put_req_header("accept", "application/json")
      |> assign(:user_id, user.id)

    {:ok, conn: conn}
  end

  describe "Withdrawal" do
    test "attempts to execute a withdrawal with a negative amount and returns the changeset error",
         %{conn: conn} do
      conn =
        post(conn, Routes.withdrawal_path(conn, :create),
          withdrawal: %{idempotency_key: "invalid request", amount: -1000}
        )

      assert %{"errors" => %{"amount" => ["must be greater than 0"]}} = json_response(conn, 422)
    end

    test "attempts to execute an invalid withdrawal returns the changeset error, then using the same idempotency key with valid withdrawal returns success, then the same request returns error ",
         %{conn: conn} do
      user = Accounts.get_user!(conn.assigns.user_id)

      conn =
        post(conn, Routes.withdrawal_path(conn, :create),
          withdrawal: %{idempotency_key: "idempotency requests", amount: -1000}
        )

      conn =
        post(conn, Routes.withdrawal_path(conn, :create),
          withdrawal: %{idempotency_key: "idempotency requests", amount: 1000}
        )

      assert %{"user" => updated_user, "withdrawal" => withdrawal} = json_response(conn, 201)

      assert updated_user["id"] == user.id
      assert updated_user["balance"] == user.balance - 1000
      assert withdrawal["amount"] == 1000
      refute is_nil(withdrawal["id"])

      conn =
        post(conn, Routes.withdrawal_path(conn, :create),
          withdrawal: %{idempotency_key: "idempotency requests", amount: 1000}
        )

      assert %{"message" => "transaction_already_finished", "withdrawal" => last_withdrawal} =
               json_response(conn, 400)

      assert last_withdrawal == withdrawal
    end
  end
end
