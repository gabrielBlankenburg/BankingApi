defmodule BankingApi.CommonFixtures do
  @moduledoc false
  alias BankingApi.Accounts
  alias BankingApi.Transactions

  @user_attrs %{
    balance: 42,
    email: "user@email.com",
    name: "Some User",
    password: "some password_hash",
    profile: :user
  }

  @withdraw_attrs %{amount: 42, idempotency_key: "some idempotency_key", status: :success}

  @transfer_attrs %{amount: 42, idempotency_key: "some idempotency_key", status: :success}
  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(@user_attrs)
      |> Accounts.create_user()

    user
  end

  def withdraw_fixture(attrs \\ %{}) do
    {:ok, withdraw} =
      attrs
      |> Enum.into(@withdraw_attrs)
      |> Transactions.create_withdraw()

    withdraw
  end

  def transfer_fixture(attrs \\ %{}) do
    {:ok, transfer} =
      attrs
      |> Enum.into(@transfer_attrs)
      |> Transactions.create_transfer()

    transfer
  end
end
