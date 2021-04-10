defmodule BankingApi.Reports.TransactionsCache do
  @moduledoc """
  Caches for the Transactions Reports for specific periods.
  The periods are based on the transactions `:inserted_at` field
  """
  use GenServer
  alias Phoenix.PubSub
  alias BankingApi.Reports
  alias BankingApi.Transactions.{Transfer, Withdraw}

  @valid_periods [:daily, :monthly, :yearly, :total]
  @refresh_period 1 * 24 * 60 * 60 * 1000

  @doc """
  Starts the worker for the given `period`
  """
  def start_link(period) when period in @valid_periods do
    GenServer.start_link(__MODULE__, %{period: period, data: []}, name: registered_name(period))
  end

  @doc """
  Finds the data by `period` filtering every date higher or equal to `range_start` and lower or equal to `range_end`
  """
  def get_period_in_range(period, range_start, range_end) do
    period
    |> get_period()
    |> Stream.filter(fn {date, _} -> Date.compare(range_start, date) in [:lt, :eq] end)
    |> Enum.filter(fn {date, _} -> Date.compare(range_end, date) in [:gt, :eq] end)
  end

  @doc """
  Fetches the period from the cache holding it. if the cache is not available on the moment, it fetches the data
  directly from the database.
  """
  def get_period(period) do
    pid =
      period
      |> registered_name()
      |> Process.whereis()

    case pid do
      nil -> fetch_data(period)
      pid -> GenServer.call(pid, :get_data)
    end
  end

  @impl true
  def init(state) do
    send(self(), :init)
    {:ok, state}
  end

  @impl true
  def handle_info(:init, state) do
    send(self(), :fetch_data)
    PubSub.subscribe(BankingApi.PubSub, "transactions")
    {:noreply, state}
  end

  def handle_info(:fetch_data, state) do
    updated_state = Map.put(state, :data, fetch_data(state.period))
    Process.send_after(self(), :fetch_data, @refresh_period)
    {:noreply, updated_state}
  end

  # It is called when Phoenix.PubSub broadcasts a new successful transaction this function incremets the new transaction
  # amount instead of refetching every record on database.
  def handle_info({module, :success, %{transaction: transaction}}, state)
      when module in [Transfer, Withdraw] do
    updated_data =
      transaction
      |> get_period_key_by_transaction(state.period)
      |> update_date_to_state_data(transaction, state.data)

    updated_state = Map.put(state, :data, updated_data)

    {:noreply, updated_state}
  end

  def handle_info(_, state), do: {:noreply, state}

  @impl true
  def handle_call(:get_data, _from, state) do
    {:reply, state.data, state}
  end

  defp get_period_key_by_transaction(_, :total), do: :total

  defp get_period_key_by_transaction(transaction, :daily) do
    transaction
    |> Map.get(:inserted_at)
    |> NaiveDateTime.to_date()
  end

  defp get_period_key_by_transaction(transaction, :monthly) do
    transaction
    |> Map.get(:inserted_at)
    |> NaiveDateTime.to_date()
    |> Date.beginning_of_month()
  end

  defp get_period_key_by_transaction(transaction, :yearly) do
    transaction
    |> Map.get(:inserted_at)
    |> NaiveDateTime.to_date()
    |> Map.get(:year)
    |> Date.new(1, 1)
  end

  defp update_date_to_state_data(key, transaction, data) do
    case Enum.find_index(data, fn {data_key, _} -> data_key == key end) do
      nil ->
        [{key, transaction.amount} | data]

      position ->
        List.update_at(data, position, fn {data_key, amount} ->
          {data_key, amount + transaction.amount}
        end)
    end
  end

  # Sorts the date by the highest to the lowerest
  defp fetch_data(period) do
    period
    |> Reports.build_transactions_report()
    |> Stream.into([])
    |> Enum.sort(fn {d1, _}, {d2, _} -> Date.compare(d1, d2) == :gt end)
  end

  defp registered_name(:daily), do: __MODULE__.Daily
  defp registered_name(:monthly), do: __MODULE__.Monthly
  defp registered_name(:yearly), do: __MODULE__.Yearly
  defp registered_name(:total), do: __MODULE__.Total
end
