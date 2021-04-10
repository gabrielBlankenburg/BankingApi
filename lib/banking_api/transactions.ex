defmodule BankingApi.Transactions do
  @moduledoc """
  The Transactions context.
  This context is currently responsible for handling withdrawals and transfers executions.
  Both withdrawals and transfers have their whole CRUD (except the delete) in here plus the insert business rules.
  NOTE: The deletion functions were removed because we want to keep log of everything.
  """

  import Ecto.Query, warn: false
  alias BankingApi.Repo
  alias BankingApi.Transactions.{Withdraw, Transfer}
  alias BankingApi.Notifier.TransactionEmail
  alias Phoenix.PubSub

  @doc """
  Returns the list of withdrawals.

  ## Examples

      iex> list_withdrawals()
      [%Withdraw{}, ...]

  """
  def list_withdrawals do
    Repo.all(Withdraw)
  end

  @doc """
  Gets a single withdraw.

  Raises `Ecto.NoResultsError` if the withdraw does not exist.

  ## Examples

      iex> get_withdraw!(123)
      %Withdraw{}

      iex> get_withdraw!(456)
      ** (Ecto.NoResultsError)

  """
  def get_withdraw!(id), do: Repo.get!(Withdraw, id)

  @doc """
  Creates a withdraw.

  ## Examples

      iex> create_withdraw(%{field: value})
      {:ok, %Withdraw{}}

      iex> create_withdraw(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """

  def create_withdraw(attrs \\ %{}) do
    %Withdraw{}
    |> Withdraw.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a withdraw.

  ## Examples

      iex> update_withdraw(withdraw, %{field: new_value})
      {:ok, %Withdraw{}}

      iex> update_withdraw(withdraw, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_withdraw(%Withdraw{} = withdraw, attrs) do
    withdraw
    |> Withdraw.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking withdraw changes.

  ## Examples

      iex> change_withdraw(withdraw)
      %Ecto.Changeset{data: %Withdraw{}}

  """
  def change_withdraw(%Withdraw{} = withdraw, attrs \\ %{}) do
    Withdraw.changeset(withdraw, attrs)
  end

  alias BankingApi.Transactions.Transfer

  @doc """
  Returns the list of transfers.

  ## Examples

      iex> list_transfers()
      [%Transfer{}, ...]

  """
  def list_transfers do
    Repo.all(Transfer)
  end

  @doc """
  Gets a single transfer.

  Raises `Ecto.NoResultsError` if the Transfer does not exist.

  ## Examples

      iex> get_transfer!(123)
      %Transfer{}

      iex> get_transfer!(456)
      ** (Ecto.NoResultsError)

  """
  def get_transfer!(id), do: Repo.get!(Transfer, id)

  @doc """
  Creates a transfer.

  ## Examples

      iex> create_transfer(%{field: value})
      {:ok, %Transfer{}}

      iex> create_transfer(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_transfer(attrs \\ %{}) do
    %Transfer{}
    |> Transfer.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a transfer.

  ## Examples

      {:ok, %Transfer{}}
      iex> update_transfer(transfer, %{field: new_value})

      iex> update_transfer(transfer, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_transfer(%Transfer{} = transfer, attrs) do
    transfer
    |> Transfer.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking transfer changes.

  ## Examples

      iex> change_transfer(transfer)
      %Ecto.Changeset{data: %Transfer{}}

  """
  def change_transfer(%Transfer{} = transfer, attrs \\ %{}) do
    Transfer.changeset(transfer, attrs)
  end

  @doc """
  Executes the `BankingApi.Transactions.withdraw.create_transaction` and handles its return.
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
  def create_withdraw_transaction(attrs \\ %{}) do
    attrs
    |> Enum.into(%{"status" => :success})
    |> create_transaction(Withdraw)
  end

  @doc """
  Similar to `create_withdraw_transaction/1`, but creates a transfer instead
  """
  def create_transfer_transaction(attrs \\ %{}) do
    attrs
    |> Enum.into(%{"status" => :success})
    |> create_transaction(Transfer)
  end

  defp create_transaction(attrs, module) do
    attrs
    |> module.create_transaction()
    |> Repo.transaction()
    |> TransactionEmail.notify()
    |> handle_transaction(attrs, module)
  end

  defp handle_transaction({:ok, data}, _, Transfer) do
    broadcast_transaction(Transfer, :success, data)

    {:ok,
     %{transaction: Map.get(data, :transaction), updated_user: Map.get(data, :updated_from_user)}}
  end

  defp handle_transaction({:ok, data}, _, withdraw) do
    broadcast_transaction(withdraw, :success, data)
    {:ok, %{transaction: Map.get(data, :transaction), updated_user: Map.get(data, :updated_user)}}
  end

  # Returns the transaction with the given idempotency_key.
  defp handle_transaction(
         {:error, :check_idempotency_key, :already_taken, %{transaction: transaction}},
         _,
         module
       ) do
    key = Map.get(transaction, :idempotency_key)

    previous_transaction = Repo.get_by!(module, idempotency_key: key, status: :success)

    {:error, {:transaction_already_finished, previous_transaction}}
  end

  defp handle_transaction(
         {:error, _step, data, _},
         attrs,
         Withdraw
       ) do
    %{"status" => :fail}
    |> Enum.into(attrs)
    |> create_withdraw()

    {:error, data}
  end

  defp handle_transaction(
         {:error, _step, data, _},
         attrs,
         Transfer
       ) do
    %{"status" => :fail}
    |> Enum.into(attrs)
    |> create_transfer()

    {:error, data}
  end

  defp broadcast_transaction(module, status, data) do
    PubSub.broadcast(BankingApi.PubSub, "transactions", {module, status, data})
  end
end
