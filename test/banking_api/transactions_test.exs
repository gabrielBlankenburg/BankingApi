defmodule BankingApi.TransactionsTest do
  use BankingApi.DataCase
  import BankingApi.CommonFixtures

  alias BankingApi.Transactions
  alias BankingApi.Accounts

  describe "withdrawals" do
    alias BankingApi.Transactions.Withdrawal

    setup do
      %{user: user_fixture()}
    end

    @valid_attrs %{amount: 42, idempotency_key: "some idempotency_key", status: :success}
    @update_attrs %{amount: 43, idempotency_key: "some updated idempotency_key", status: :success}
    @invalid_attrs %{amount: nil, idempotency_key: nil, status: nil}

    def withdrawal_fixture(attrs \\ %{}) do
      {:ok, withdrawal} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Transactions.create_withdrawal()

      withdrawal
    end

    test "list_withdrawals/0 returns all withdrawals", %{user: user} do
      withdrawal = withdrawal_fixture(%{user_id: user.id})
      assert Transactions.list_withdrawals() == [withdrawal]
    end

    test "get_withdrawal!/1 returns the withdrawal with given id", %{user: user} do
      withdrawal = withdrawal_fixture(%{user_id: user.id})
      assert Transactions.get_withdrawal!(withdrawal.id) == withdrawal
    end

    test "create_withdrawal/1 with valid data creates a withdrawal", %{user: user} do
      assert {:ok, %Withdrawal{} = withdrawal} =
               @valid_attrs
               |> Enum.into(%{user_id: user.id})
               |> Transactions.create_withdrawal()

      assert withdrawal.amount == 42
      assert withdrawal.idempotency_key == "some idempotency_key"
      assert withdrawal.status == :success
    end

    test "create_withdrawal/1 with invalid data returns error changeset", _ do
      assert {:error, %Ecto.Changeset{}} = Transactions.create_withdrawal(@invalid_attrs)
    end

    test "update_withdrawal/2 with valid data updates the withdrawal", %{user: user} do
      withdrawal = withdrawal_fixture(%{user_id: user.id})

      assert {:ok, %Withdrawal{} = withdrawal} =
               Transactions.update_withdrawal(withdrawal, @update_attrs)

      assert withdrawal.amount == 43
      assert withdrawal.idempotency_key == "some updated idempotency_key"
      assert withdrawal.status == :success
    end

    test "update_withdrawal/2 with invalid data returns error changeset", %{user: user} do
      withdrawal = withdrawal_fixture(%{user_id: user.id})

      assert {:error, %Ecto.Changeset{}} =
               Transactions.update_withdrawal(withdrawal, @invalid_attrs)

      assert withdrawal == Transactions.get_withdrawal!(withdrawal.id)
    end

    test "change_withdrawal/1 returns a withdrawal changeset", %{user: user} do
      withdrawal = withdrawal_fixture(%{user_id: user.id})
      assert %Ecto.Changeset{} = Transactions.change_withdrawal(withdrawal)
    end
  end

  describe "withdrawals transactions" do
    test "create_withdrawal_transaction/1 with valid data decrements user balance returning the updated user and transaction" do
      user = user_fixture(%{email: "valid_transaction@email.com", balance: 10_000})

      assert {:ok, %{transaction: transaction, updated_user: updated_user}} =
               Transactions.create_withdrawal_transaction(%{
                 "amount" => 1_000,
                 "idempotency_key" => "valid transaction",
                 "user_id" => user.id
               })

      assert transaction.amount == 1_000
      assert transaction.user_id == user.id
      assert transaction.status == :success
      refute is_nil(transaction.id)
      assert updated_user.id == user.id
      assert updated_user.balance == 9_000
    end

    test "create_withdrawal_transaction/1 when user doesn't have enough ballance returns an error" do
      user = user_fixture(%{email: "valid_transaction@email.com", balance: 1_000})

      assert {:error, %Ecto.Changeset{}} =
               Transactions.create_withdrawal_transaction(%{
                 "amount" => 2_000,
                 "idempotency_key" => "invalid balance",
                 "user_id" => user.id
               })

      assert Accounts.get_user!(user.id) == Map.put(user, :password, nil)
    end

    test "create_withdrawal_transaction/1 when idempotency is duplicated and status is :success will return an error" do
      user = user_fixture(%{email: "idempotency_transaction@email.com", balance: 10_000})

      attrs = %{
        "amount" => 1_000,
        "idempotency_key" => "duplicated idempotency",
        "user_id" => user.id
      }

      assert {:error, _} =
               attrs
               |> Map.put("amount", -1)
               |> Transactions.create_withdrawal_transaction()

      assert {:ok, %{transaction: transaction}} =
               Transactions.create_withdrawal_transaction(attrs)

      assert {:error, {:transaction_already_finished, previous_transaction}} =
               Transactions.create_withdrawal_transaction(attrs)

      assert previous_transaction == transaction
    end
  end
end
