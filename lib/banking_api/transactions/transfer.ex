defmodule BankingApi.Transactions.Transfer do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.Multi
  alias BankingApi.Accounts
  alias BankingApi.Accounts.User

  @behaviour BankingApi.Transactions.Behaviour

  schema "transfers" do
    field :amount, :integer
    field :idempotency_key, :string
    field :status, Ecto.Enum, values: [:success, :fail]
    field :from, :id
    field :to, :id

    timestamps()
  end

  @doc """
  This changeset is meant to be called when the user is trying to make a transfer.
  This cannot be used as the main changeset function because `:fail` validations would never be able to be
  persisted since this changeset is what makes a withdrawal fail.
  """
  def user_changeset(transfer, attrs) do
    transfer
    |> changeset(attrs)
    |> validate_number(:amount, greater_than: 0)
  end

  @doc false
  def changeset(transfer, attrs) do
    transfer
    |> cast(attrs, [:amount, :idempotency_key, :status, :from, :to])
    |> validate_required([:amount, :idempotency_key, :status, :from, :to])
    |> foreign_key_constraint(:to)
    |> foreign_key_constraint(:from)
  end

  @doc """
  Execute every money transfer database step, if any of them fail, rollback the previous ones.
  The steps are:
  1) Attempts to insert the transfer using the `user_changeset/2` validations and checking the "success_idempotency_key" index
  that prevents duplicated `:idempotency_key` with the `:status` field setted as `:success`. If that is the case, there will
  be no changes on database, what also means that no errors will be returned, but the returned changeset will have a `nil` id.
  NOTE: The non `:success` status doesn't prevent the same `:idempotency_key` to be persisted since the failures just persists
  the data as a log, having no other side-effects.
  2) Checks if the previous transaction was a new one, based on its idempotency.
  3) Gets the "from user" data.
  4) Updates the user who is transfering money.
  5) Gets the "to user" data.
  6) Updates the user who is receiving money.
  """
  @impl true
  def create_transaction(attrs \\ %{}) do
    Multi.new()
    |> Multi.insert(:transaction, fn _ -> user_changeset(%__MODULE__{}, attrs) end,
      on_conflict: :nothing,
      conflict_target: {:unsafe_fragment, "(status, idempotency_key) WHERE status='success'"}
    )
    |> Multi.run(:check_idempotency_key, &check_idempotency_key/2)
    |> Multi.run(:from_user, &get_user_transaction(&1, &2, :from))
    |> Multi.update(:updated_from_user, &updated_from_user_transaction/1)
    |> Multi.run(:to_user, &get_user_transaction(&1, &2, :to))
    |> Multi.update(:updated_to_user, &updated_to_user_transaction/1)
  end

  # If the insert transaction was successfully and yet there is no id on the changeset, that means
  # the idempotency_key was already persisted on some record with the status :success
  defp check_idempotency_key(_, %{transaction: %{id: nil}}), do: {:error, :already_taken}
  defp check_idempotency_key(_, _), do: {:ok, :ok}

  # Since the password is never retrieved, the password is deleted from the User changeset
  defp get_user_transaction(repo, %{transaction: transaction}, field) do
    id = Map.get(transaction, field)

    case repo.get(User, id) do
      %User{} = user -> {:ok, Map.delete(user, :password)}
      nil -> {:error, :user_not_found}
    end
  end

  defp updated_from_user_transaction(%{from_user: user, transaction: transaction}) do
    balance = Map.get(user, :balance) - Map.get(transaction, :amount)
    Accounts.change_user(user, %{balance: balance})
  end

  defp updated_to_user_transaction(%{to_user: user, transaction: transaction}) do
    balance = Map.get(user, :balance) + Map.get(transaction, :amount)
    Accounts.change_user(user, %{balance: balance})
  end
end
