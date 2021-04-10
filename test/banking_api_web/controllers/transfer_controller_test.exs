defmodule BankingApiWeb.TransferControllerTest do
  @moduledoc false
  use BankingApiWeb.ConnCase

  import BankingApi.CommonFixtures
  alias BankingApi.Accounts
  alias BankingApi.Accounts.Guardian

  setup %{conn: conn} do
    user =
      user_fixture(%{profile: :user, email: "transfer_tests_user@email.com", balance: 100_000})

    {:ok, token, _} = Guardian.encode_and_sign(user)

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> put_req_header("accept", "application/json")
      |> assign(:user_id, user.id)

    {:ok, conn: conn}
  end

  describe "Transfers" do
    test "attempts to execute a transfer with a negative amount and returns the changeset error",
         %{conn: conn} do
      to_user = user_fixture(%{email: "invalid_transfer_amount@email.com"})

      conn =
        post(conn, Routes.transfer_path(conn, :create),
          transfer: %{idempotency_key: "invalid request", amount: -1000, to: to_user.id}
        )

      assert %{"errors" => %{"amount" => ["must be greater than 0"]}} = json_response(conn, 422)
    end

    test "attempts to execute an invalid transfer returns the changeset error, then using the same idempotency key with valid transfer returns success, then the same request returns error ",
         %{conn: conn} do
      from_user = Accounts.get_user!(conn.assigns.user_id)
      to_user = user_fixture(%{email: "duplicated_idempotency_key@email.com"})

      conn =
        post(conn, Routes.transfer_path(conn, :create),
          transfer: %{idempotency_key: "idempotency requests", amount: -1000, to: to_user.id}
        )

      conn =
        post(conn, Routes.transfer_path(conn, :create),
          transfer: %{idempotency_key: "idempotency requests", amount: 1000, to: to_user.id}
        )

      assert %{"user" => updated_user, "transfer" => transfer} = json_response(conn, 201)

      assert updated_user["id"] == from_user.id
      assert updated_user["balance"] == from_user.balance - 1000
      assert transfer["amount"] == 1000

      assert to_user.id
             |> Accounts.get_user!()
             |> Map.get(:balance) == to_user.balance + 1000

      refute is_nil(transfer["id"])

      conn =
        post(conn, Routes.transfer_path(conn, :create),
          transfer: %{idempotency_key: "idempotency requests", amount: 1000, to: to_user.id}
        )

      assert %{"message" => "transaction_already_finished", "transfer" => last_transfer} =
               json_response(conn, 400)

      assert last_transfer == transfer
    end
  end
end
