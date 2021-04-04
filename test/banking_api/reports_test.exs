defmodule BankingApi.ReportsTest do
  use BankingApi.DataCase
  import BankingApi.CommonFixtures
  alias BankingApi.{Repo, Reports}

  describe "Transactions report without persisted data" do
    test "build_transactions_report/1 with :total returns %{total: 0}" do
      assert Reports.build_transactions_report(:total) == %{total: 0}
    end

    test "build_transactions_report/1 with :yearly returns an empty map" do
      assert Reports.build_transactions_report(:yearly) == %{}
    end

    test "build_transactions_report/1 with :monthly returns an empty map" do
      assert Reports.build_transactions_report(:monthly) == %{}
    end

    test "build_transactions_report/1 with :daily returns an empty map" do
      assert Reports.build_transactions_report(:daily) == %{}
    end

    test "get_transaction_report_by_period/1 with :total returns {:ok, [total: 0]}" do
      assert Reports.get_transaction_report_by_period(:total) == {:ok, [total: 0]}
      assert Reports.get_transaction_report_by_period("total") == {:ok, [total: 0]}
    end

    test "get_transaction_report_by_period/1 with :daily returns {:ok, []}" do
      assert Reports.get_transaction_report_by_period(:daily) == {:ok, []}
      assert Reports.get_transaction_report_by_period("daily") == {:ok, []}
    end

    test "get_transaction_report_by_period/1 with :invalid returns {:error, :invalid_period}" do
      assert Reports.get_transaction_report_by_period(:invalid) == {:error, :invalid_period}
      assert Reports.get_transaction_report_by_period("invalid") == {:error, :invalid_period}
    end
  end

  describe "Transactions report with persisted data" do
    setup do
      user1 = user_fixture(%{amount: 10_000, email: "user1@email.com"})
      user2 = user_fixture(%{amount: 10_000, email: "user2@email.com"})

      # Creates 2 withdrawals with success, 1 with failure, 2 transfers with succes, 1 with failure
      # each one attempting to do a transaction of R$ 10.00.
      # The total successfully amount is R$ 40.00.
      withdrawal_fixture(%{user_id: user1.id, amount: 1_000, idempotency_key: "withdrawal 1"})

      withdrawal_fixture(%{
        user_id: user1.id,
        amount: 1_000,
        idempotency_key: "withdrawal 1",
        status: :fail
      })

      withdrawal_fixture(%{user_id: user2.id, amount: 1_000, idempotency_key: "withdrawal 2"})

      transfer_fixture(%{
        from: user1.id,
        to: user2.id,
        amount: 1_000,
        idempotency_key: "transfer 1"
      })

      transfer_fixture(%{
        from: user1.id,
        to: user2.id,
        amount: 1_000,
        idempotency_key: "transfer 1",
        status: :fail
      })

      transfer_fixture(%{
        from: user2.id,
        to: user1.id,
        amount: 1_000,
        idempotency_key: "transfer 2"
      })

      {:ok, %{fixture_date: Date.utc_today()}}
    end

    test "build_transactions_report/1 with :total returns %{total: 4000}", _ do
      assert Reports.build_transactions_report(:total) == %{total: 4_000}
    end

    test "build_transactions_report/1 with :yearly returns %{date: 4000}", %{fixture_date: date} do
      formated_date =
        date
        |> Map.get(:year)
        |> Date.new!(1, 1)

      assert Reports.build_transactions_report(:yearly) == %{formated_date => 4_000}
    end

    test "build_transactions_report/1 with :monthly returns %{date: 4000}", %{fixture_date: date} do
      formated_date = Date.beginning_of_month(date)
      assert Reports.build_transactions_report(:monthly) == %{formated_date => 4_000}
    end

    test "build_transactions_report/1 with :daily returns %{date: 4000}", %{fixture_date: date} do
      assert Reports.build_transactions_report(:daily) == %{date => 4_000}
    end

    test "get_transaction_report_by_period/1 with :total returns {:ok, [total: 4000]}", _ do
      assert Reports.get_transaction_report_by_period(:total) == {:ok, [total: 4_000]}
      assert Reports.get_transaction_report_by_period("total") == {:ok, [total: 4_000]}
    end

    test "get_transaction_report_by_period/1 with :daily returns {:ok, [{date, 4000}]}", %{
      fixture_date: date
    } do
      assert Reports.get_transaction_report_by_period(:daily) == {:ok, [{date, 4_000}]}
      assert Reports.get_transaction_report_by_period("daily") == {:ok, [{date, 4_000}]}
    end
  end
end
