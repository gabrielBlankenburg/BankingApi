defmodule BankingApi.Transactions.Withdraw do
  @moduledoc """
  Withdrawl
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.Multi
  alias BankingApi.Accounts
  alias BankingApi.Accounts.User

  @behaviour BankingApi.Transactions.Behaviour

  schema "withdrawals" do
    field :amount, :integer
    field :idempotency_key, :string
    field :status, Ecto.Enum, values: [:success, :fail]
    belongs_to :user, User, foreign_key: :user_id

    timestamps()
  end

  @doc """
  This changeset is meant to be called when the user is trying to make a withdraw.
  This cannot be used as the main changeset function because `:fail` validations would never be able to be
  persisted since this changeset is what makes a withdraw fail.
  """
  def user_changeset(withdraw, attrs) do
    withdraw
    |> changeset(attrs)
    |> validate_number(:amount, greater_than: 0)
  end

  @doc false
  def changeset(withdraw, attrs) do
    withdraw
    |> cast(attrs, [:user_id, :amount, :status, :idempotency_key])
    |> validate_required([:user_id, :amount, :status, :idempotency_key])
    |> foreign_key_constraint(:user_id)
  end

  @doc """
  Execute every withdraw database step, if any of them fail, rollback the previous ones.
  The steps are:
  1) Attempts to insert the withdraw using the `user_changeset/2` validations and checking the "success_idempotency_key" index
  that prevents duplicated `:idempotency_key` with the `:status` field setted as `:success`. If that is the case, there will
  be no changes on database, what also means that no errors will be returned, but the returned changeset will have a `nil` id.
  NOTE: The non `:success` status doesn't prevent the same `:idempotency_key` to be persisted since the failures just persists
  the data as a log, having no other side-effects.
  2) Checks if the previous transaction was a new one, based on its idempotency.
  3) Gets the user data (so the balance can be used on the next step).
  4) Updates the user ballance.
  """
  @impl true
  def create_transaction(attrs \\ %{}) do
    Multi.new()
    |> Multi.insert(:transaction, fn _ -> user_changeset(%__MODULE__{}, attrs) end,
      on_conflict: :nothing,
      conflict_target: {:unsafe_fragment, "(status, idempotency_key) WHERE status='success'"}
    )
    |> Multi.run(:check_idempotency_key, &check_idempotency_key/2)
    |> Multi.run(:user, &get_user_transaction/2)
    |> Multi.update(:updated_user, &update_user_transaction/1)
  end

  # If the insert transaction was successfully and yet there is no id on the changeset, that means
  # the idempotency_key was already persisted on some record with the status :success
  defp check_idempotency_key(_, %{transaction: %{id: nil}}), do: {:error, :already_taken}
  defp check_idempotency_key(_, _), do: {:ok, :ok}

  # Since the password is never retrieved, the password is deleted from the User changeset
  defp get_user_transaction(repo, %{transaction: %__MODULE__{user_id: id}}) do
    case repo.get(User, id) do
      %User{} = user -> {:ok, Map.delete(user, :password)}
      nil -> {:error, :user_not_found}
    end
  end

  defp update_user_transaction(%{user: user, transaction: transaction}) do
    balance = Map.get(user, :balance) - Map.get(transaction, :amount)
    Accounts.change_user(user, %{balance: balance})
  end
end
