defmodule BankingApi.Repo.Migrations.CreateWithdrawals do
  use Ecto.Migration

  def change do
    create table(:withdrawals) do
      add :amount, :bigint
      add :status, :string
      add :idempotency_key, :string
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:withdrawals, [:user_id])
    create unique_index(:withdrawals, [:idempotency_key, :status], name: "success_idempotency_key", where: "status = 'success'")
  end
end
