defmodule BankingApi.Transactions do
  @moduledoc """
  The Transactions context.
  """

  import Ecto.Query, warn: false
  alias BankingApi.Repo
  alias BankingApi.Transactions.Withdrawal
  alias Phoenix.PubSub

  @doc """
  Returns the list of withdrawals.

  ## Examples

      iex> list_withdrawals()
      [%Withdrawal{}, ...]

  """
  def list_withdrawals do
    Repo.all(Withdrawal)
  end

  @doc """
  Gets a single withdrawal.

  Raises `Ecto.NoResultsError` if the Withdrawal does not exist.

  ## Examples

      iex> get_withdrawal!(123)
      %Withdrawal{}

      iex> get_withdrawal!(456)
      ** (Ecto.NoResultsError)

  """
  def get_withdrawal!(id), do: Repo.get!(Withdrawal, id)

  @doc """
  Creates a withdrawal.

  ## Examples

      iex> create_withdrawal(%{field: value})
      {:ok, %Withdrawal{}}

      iex> create_withdrawal(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """

  def create_withdrawal(attrs \\ %{}) do
    %Withdrawal{}
    |> Withdrawal.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a withdrawal.

  ## Examples

      iex> update_withdrawal(withdrawal, %{field: new_value})
      {:ok, %Withdrawal{}}

      iex> update_withdrawal(withdrawal, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_withdrawal(%Withdrawal{} = withdrawal, attrs) do
    withdrawal
    |> Withdrawal.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking withdrawal changes.

  ## Examples

      iex> change_withdrawal(withdrawal)
      %Ecto.Changeset{data: %Withdrawal{}}

  """
  def change_withdrawal(%Withdrawal{} = withdrawal, attrs \\ %{}) do
    Withdrawal.changeset(withdrawal, attrs)
  end

  @doc """
  Executes the `BankingApi.Transactions.Withdrawal.create_transaction` and handles its return.
  In case of success, an email is sent and a new message is sent to every process listening to the topic `"transactions"`.
  In case of failure, there are two possible actions:
  1) The transaction failed because it was already completed (verified by the `idempotency_key`), then the actual completed
  transaction is fetched and returned inside the tuple {:error, {:transaction_already_finished, previous_transaction}}`
  2) Some other step of the transaction failed, then it persists a failure on the database and returns the error from the
  transaction.
  NOTE: Since this request is most likely to be called from controllers and controllers receives string maps, the `attrs`
  is expected to be a string map too, this is necessary because the schemas changeset cannot handle a mixed (key and string) maps
  and this functions injects some data into the `attrs` like `%{"status" => :success}` what makes it necessary to receive string maps.
  """
  def create_withdrawal_transaction(attrs \\ %{}) do
    attrs
    |> Enum.into(%{"status" => :success})
    |> Withdrawal.create_transaction()
    |> Repo.transaction()
    |> handle_withdrawal_transaction(attrs)
  end

  defp handle_withdrawal_transaction({:ok, data}, _) do
    PubSub.broadcast(BankingApi.PubSub, "transactions", {:withdrawal, :success, data})
    {:ok, %{transaction: Map.get(data, :transaction), updated_user: Map.get(data, :updated_user)}}
  end

  # Returns the transaction with the given idempotency_key.
  defp handle_withdrawal_transaction(
         {:error, :check_idempotency_key, :already_taken, %{transaction: transaction}},
         _
       ) do
    key = Map.get(transaction, :idempotency_key)
    previous_transaction = Repo.get_by!(Withdrawal, idempotency_key: key, status: :success)
    {:error, {:transaction_already_finished, previous_transaction}}
  end

  defp handle_withdrawal_transaction(
         {:error, _step, data, _},
         attrs
       ) do
    attrs
    |> Enum.into(%{"status" => :fail})
    |> create_withdrawal()

    {:error, data}
  end
end
