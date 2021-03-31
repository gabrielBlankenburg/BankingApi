defmodule BankingApi.Repo.Migrations.CreateTransfers do
  use Ecto.Migration

  def change do
    create table(:transfers) do
      add :amount, :bigint
      add :idempotency_key, :string
      add :status, :string
      add :from, references(:users, on_delete: :nothing)
      add :to, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:transfers, [:from])
    create index(:transfers, [:to])
    create unique_index(:transfers, [:idempotency_key, :status], name: "transfers_success_idempotency_key", where: "status = 'success'")
  end
end
