defmodule BankingApi.CommonFixtures do
  alias BankingApi.Accounts
  alias BankingApi.Transactions

  @user_attrs %{
    balance: 42,
    email: "user@email.com",
    password: "some password_hash",
    profile: :user
  }

  @withdrawal_attrs %{amount: 42, idempotency_key: "some idempotency_key", status: :success}

  @transfer_attrs %{amount: 42, idempotency_key: "some idempotency_key", status: :success}
  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(@user_attrs)
      |> Accounts.create_user()

    user
  end

  def withdrawal_fixture(attrs \\ %{}) do
    {:ok, withdrawal} =
      attrs
      |> Enum.into(@withdrawal_attrs)
      |> Transactions.create_withdrawal()

    withdrawal
  end

  def transfer_fixture(attrs \\ %{}) do
    {:ok, transfer} =
      attrs
      |> Enum.into(@transfer_attrs)
      |> Transactions.create_transfer()

    transfer
  end
end
