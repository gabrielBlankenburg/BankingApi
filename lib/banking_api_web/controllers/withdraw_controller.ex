defmodule BankingApiWeb.WithdrawController do
  @moduledoc """
  The withdraw controller.
  Only the current authorized user can make withdrawals.
  """
  use BankingApiWeb, :controller
  alias BankingApi.Transactions

  action_fallback BankingApiWeb.FallbackController

  def create(conn, %{"withdraw" => withdraw}) do
    withdraw
    |> Enum.into(%{"user_id" => conn.assigns[:user_id]})
    |> Transactions.create_withdraw_transaction()
    |> handle_transaction(conn)
  end

  defp handle_transaction({:ok, data}, conn) do
    conn
    |> put_status(:created)
    |> render("show.json", withdraw: data.transaction, user: data.updated_user)
  end

  defp handle_transaction({:error, {:transaction_already_finished, withdraw}}, conn) do
    conn
    |> put_status(:bad_request)
    |> render("show.json", withdraw: withdraw, message: :transaction_already_finished)
  end

  defp handle_transaction({:error, _} = data, _conn), do: data
end
