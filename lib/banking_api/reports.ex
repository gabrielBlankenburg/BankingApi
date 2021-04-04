defmodule BankingApi.Reports do
  @moduledoc """
  Context for reports
  """
  alias BankingApi.Transactions.{Transfer, Withdrawal}
  alias BankingApi.Repo
  alias BankingApi.Reports.TransactionsCache
  import Ecto.Query

  @valid_periods [:daily, :monthly, :yearly, :total]

  @doc """
  Fetches the reports by period from transferts and withdrawals, then concatenate them suming the values for each period
  """
  def build_transactions_report(:total) do
    Withdrawal
    |> transaction_query_total()
    |> Stream.concat(transaction_query_total(Transfer))
    |> Enum.reduce(%{total: 0}, fn
      %{amount: nil}, acc ->
        acc

      %{amount: amount}, %{total: total} ->
        %{total: amount + total}
    end)
  end

  def build_transactions_report(period) when period in @valid_periods do
    withdrawals = transaction_query_all(Withdrawal, period)
    transfers = transaction_query_all(Transfer, period)

    withdrawals
    |> Stream.concat(transfers)
    |> Enum.reduce(%{}, &group_transactions_by_period/2)
  end

  @doc """
  If a valid period is provided, fetches it from the `BankingApi.Reports.TransactionsCache`.
  Returns {:ok, data} or {:error, reason}
  """
  def get_transaction_report_by_period(period) when is_binary(period) do
    case get_atom_period(period) do
      nil -> invalid_period_error(period)
      atom -> get_transaction_report_by_period(atom)
    end
  end

  def get_transaction_report_by_period(period) when period in @valid_periods do
    {:ok, TransactionsCache.get_period(period)}
  end

  def get_transaction_report_by_period(period), do: invalid_period_error(period)

  @doc """
  Similar to `get_transaction_report_by_period/1` but receives a date range.
  """
  def get_transaction_report_by_period_in_range(period, range_start, range_end)
      when is_binary(period) do
    case get_atom_period(period) do
      nil -> invalid_period_error(period)
      atom -> get_transaction_report_by_period_in_range(atom, range_start, range_end)
    end
  end

  def get_transaction_report_by_period_in_range(period, range_start, range_end)
      when period in @valid_periods do
    {:ok, TransactionsCache.get_period_in_range(period, range_start, range_end)}
  end

  def get_transaction_report_by_period_in_range(period, _, _), do: invalid_period_error(period)

  # The try catch is necessary because the String.to_existing_atom/1 raises an error
  # if the atom doesn't exist. It's not a good idea just using String.to_atom/1 since
  # these data are mostly coming from external requests and atoms aren't garbage collected.
  defp get_atom_period(period) do
    try do
      String.to_existing_atom(period)
    rescue
      _ -> nil
    end
  end

  defp invalid_period_error(_period), do: {:error, :invalid_period}

  defp group_transactions_by_period(record, acc) do
    start_date = NaiveDateTime.to_date(record.date)

    case Map.get(acc, start_date) do
      nil -> Map.put(acc, start_date, record.amount)
      amount -> Map.put(acc, start_date, amount + record.amount)
    end
  end

  defp transaction_query_all(module, period) do
    date_trunc =
      case period do
        :yearly -> "year"
        :monthly -> "month"
        :daily -> "day"
      end

    module
    |> where([w], w.status == :success)
    |> select([w], %{
      date: fragment("date_trunc(?, ?)", ^date_trunc, w.inserted_at),
      amount: fragment("cast(? as integer)", sum(w.amount))
    })
    |> group_by(1)
    |> Repo.all()
  end

  defp transaction_query_total(module) do
    module
    |> where([w], w.status == :success)
    |> select([w], %{amount: fragment("cast(? as integer)", sum(w.amount))})
    |> Repo.all()
  end
end
