defmodule BankingApiWeb.WithdrawalController do
  @moduledoc """
  The Withdrawal controller.
  Only the current authorized user can make withdrawals.
  """
  use BankingApiWeb, :controller
  alias BankingApi.Transactions

  action_fallback BankingApiWeb.FallbackController

  def create(conn, %{"withdrawal" => withdrawal}) do
    withdrawal
    |> Enum.into(%{"user_id" => conn.assigns[:user_id]})
    |> Transactions.create_withdrawal_transaction()
    |> handle_transaction(conn)
  end

  defp handle_transaction({:ok, data}, conn) do
    conn
    |> put_status(:created)
    |> render("show.json", withdrawal: data.transaction, user: data.updated_user)
  end

  defp handle_transaction({:error, {:transaction_already_finished, withdrawal}}, conn) do
    conn
    |> put_status(:bad_request)
    |> render("show.json", withdrawal: withdrawal, message: :transaction_already_finished)
  end

  defp handle_transaction({:error, _} = data, _conn), do: data
end
