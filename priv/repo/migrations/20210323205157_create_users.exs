defmodule BankingApi.Repo.Migrations.CreateUsers do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string
      add :name, :string
      add :password_hash, :string
      add :profile, :string
      add :balance, :bigint
      timestamps()
    end

    create unique_index(:users, [:email])
  end
end
