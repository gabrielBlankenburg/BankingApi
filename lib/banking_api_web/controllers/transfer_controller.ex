defmodule BankingApiWeb.TransferController do
  @moduledoc """
  The Transfer controller.
  Only the current authorized user can make Transfers.
  """
  use BankingApiWeb, :controller
  alias BankingApi.Transactions

  action_fallback BankingApiWeb.FallbackController

  def create(conn, %{"transfer" => transfer}) do
    transfer
    |> Enum.into(%{"from" => conn.assigns[:user_id]})
    |> Transactions.create_transfer_transaction()
    |> handle_transaction(conn)
  end

  defp handle_transaction({:ok, data}, conn) do
    conn
    |> put_status(:created)
    |> render("show.json", transfer: data.transaction, user: data.updated_user)
  end

  defp handle_transaction({:error, {:transaction_already_finished, transfer}}, conn) do
    conn
    |> put_status(:bad_request)
    |> render("show.json", transfer: transfer, message: :transaction_already_finished)
  end

  defp handle_transaction({:error, _} = data, _conn), do: data
end
