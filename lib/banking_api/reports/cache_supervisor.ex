defmodule BankingApi.Reports.CacheSupervisor do
  @moduledoc """
  Starts the Reports Caches.
  This supervisor is meant to start a `BankingApi.Reports.TransactionsCache` for each valid period.
  """
  use Supervisor
  alias BankingApi.Reports.TransactionsCache

  @doc """
  Starts the supervisor with the periods `:total`, `:yearly`, `:monthly`, `:daily`
  Available `args` keys are:
  `:accepted_envs`: A list of the envs where this supervisor can be started. If none is provided, the `[:dev, :prod]`
  will be considered. It's required because this supervisor is started from the top level supervisor and the
  tests can't run this before the mocked Repo starts. A simple `restart: :transient` would fix it but an error
  would be raisen (because this supervisor would just crash) in the beggining of the tests what is not that intuitive.
  """
  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(args) do
    children = [
      %{
        id: :daily,
        start: {TransactionsCache, :start_link, [:daily]}
      },
      %{
        id: :monthly,
        start: {TransactionsCache, :start_link, [:monthly]}
      },
      %{
        id: :yearly,
        start: {TransactionsCache, :start_link, [:yearly]}
      },
      %{
        id: :total,
        start: {TransactionsCache, :start_link, [:total]}
      }
    ]

    if Application.get_env(:banking_api, :env) in Keyword.get(args, :accepted_envs, [:dev, :prod]) do
      Supervisor.init(children, strategy: :one_for_one)
    else
      :ignore
    end
  end
end
