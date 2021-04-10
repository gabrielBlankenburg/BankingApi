defmodule BankingApi.Transactions.Behaviour do
  @moduledoc """
  Default behaviours for the transactions schemas.
  """

  @doc """
  Gets a map and uses the `Ecto.Multi` to make a multiple step transaction into the database.
  """
  @callback create_transaction(map()) :: %Ecto.Multi{}
end
