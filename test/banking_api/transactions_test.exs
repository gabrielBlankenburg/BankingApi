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

  describe "transfers" do
    setup do
      %{
        from: user_fixture(%{email: "from_user@email.com"}).id,
        to: user_fixture(email: "to_user@email.com").id
      }
    end

    alias BankingApi.Transactions.Transfer

    @valid_attrs %{amount: 42, idempotency_key: "some idempotency_key", status: :success}
    @update_attrs %{
      amount: 43,
      idempotency_key: "some updated idempotency_key",
      status: :success
    }
    @invalid_attrs %{amount: nil, idempotency_key: nil, status: nil}

    def transfer_fixture(attrs \\ %{}) do
      {:ok, transfer} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Transactions.create_transfer()

      transfer
    end

    test "list_transfers/0 returns all transfers", %{from: from, to: to} do
      transfer = transfer_fixture(%{from: from, to: to})
      assert Transactions.list_transfers() == [transfer]
    end

    test "get_transfer!/1 returns the transfer with given id", %{from: from, to: to} do
      transfer = transfer_fixture(%{from: from, to: to})
      assert Transactions.get_transfer!(transfer.id) == transfer
    end

    test "create_transfer/1 with valid data creates a transfer", %{from: from, to: to} do
      assert {:ok, %Transfer{} = transfer} =
               @valid_attrs
               |> Enum.into(%{from: from, to: to})
               |> Transactions.create_transfer()

      assert transfer.amount == 42
      assert transfer.idempotency_key == "some idempotency_key"
      assert transfer.status == :success
    end

    test "create_transfer/1 with invalid data returns error changeset", _ do
      assert {:error, %Ecto.Changeset{}} = Transactions.create_transfer(@invalid_attrs)
    end

    test "update_transfer/2 with valid data updates the transfer", %{from: from, to: to} do
      transfer = transfer_fixture(%{from: from, to: to})
      assert {:ok, %Transfer{} = transfer} = Transactions.update_transfer(transfer, @update_attrs)
      assert transfer.amount == 43
      assert transfer.idempotency_key == "some updated idempotency_key"
      assert transfer.status == :success
    end

    test "update_transfer/2 with invalid data returns error changeset", %{from: from, to: to} do
      transfer = transfer_fixture(%{from: from, to: to})
      assert {:error, %Ecto.Changeset{}} = Transactions.update_transfer(transfer, @invalid_attrs)
      assert transfer == Transactions.get_transfer!(transfer.id)
    end

    test "change_transfer/1 returns a transfer changeset", %{from: from, to: to} do
      transfer = transfer_fixture(%{from: from, to: to})
      assert %Ecto.Changeset{} = Transactions.change_transfer(transfer)
    end
  end

  describe "transfer transactions" do
    test "create_transfer_transaction/1 with valid data decrements 'from user' balance and increments the 'to user' balance, returning the transaction and the updated 'from user' data" do
      from_user = user_fixture(%{email: "valid_from_transaction@email.com", balance: 10_000})
      to_user = user_fixture(%{email: "valid_to_transaction@email.com", balance: 10_000})

      assert {:ok, %{transaction: transaction, updated_user: updated_user}} =
               Transactions.create_transfer_transaction(%{
                 "amount" => 1_000,
                 "idempotency_key" => "valid transaction",
                 "from" => from_user.id,
                 "to" => to_user.id
               })

      updated_to_user = Accounts.get_user!(to_user.id)

      assert transaction.amount == 1_000
      assert transaction.from == from_user.id
      assert transaction.to == to_user.id
      assert transaction.status == :success
      refute is_nil(transaction.id)
      assert updated_user.id == from_user.id
      assert updated_user.balance == 9_000
      assert updated_to_user.balance == 11_000
    end

    test "create_transfer_transaction/1 when 'from user' doesn't have enough balance returns an error" do
      from_user =
        user_fixture(%{email: "invalid_balance_from_transaction@email.com", balance: 1_000})

      to_user =
        user_fixture(%{email: "invalid_balance_to_transaction@email.com", balance: 10_000})

      assert {:error, %Ecto.Changeset{}} =
               Transactions.create_transfer_transaction(%{
                 "amount" => 2_000,
                 "idempotency_key" => "invalid balance",
                 "from" => from_user.id,
                 "to" => to_user.id
               })

      assert Accounts.get_user!(from_user.id) == Map.put(from_user, :password, nil)
      assert Accounts.get_user!(to_user.id) == Map.put(to_user, :password, nil)
    end

    test "create_transfer_transaction/1 when idempotency is duplicated and status is :success will return an error" do
      from_user =
        user_fixture(%{
          email: "duplicated_idempotency_from_transaction@email.com",
          balance: 10_000
        })

      to_user =
        user_fixture(%{email: "duplicated_idempotency_to_transaction@email.com", balance: 10_000})

      attrs = %{
        "amount" => 1_000,
        "idempotency_key" => "duplicated idempotency",
        "from" => from_user.id,
        "to" => to_user.id
      }

      assert {:error, _} =
               attrs
               |> Map.put("amount", -1)
               |> Transactions.create_transfer_transaction()

      assert {:ok, %{transaction: transaction}} = Transactions.create_transfer_transaction(attrs)

      assert {:error, {:transaction_already_finished, previous_transaction}} =
               Transactions.create_transfer_transaction(attrs)

      assert previous_transaction == transaction
    end
  end
end
