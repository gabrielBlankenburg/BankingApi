defmodule BankingApi.Notifier.TransactionEmail do
  @moduledoc """
  A helper for mocking the transactions emails.
  The `notify/1` is the entrypoint that handles any transaction email we need.
  """
  alias BankingApi.Transactions.{Transfer, Withdraw}
  alias BankingApi.{Money, Repo}

  @doc """
  Since this function is more usual to be called from a pipeline handling `{:ok | :error, data}`, this is the format
  accepted.
  The same data sent is returned so the functions can keep the pipeline.
  """
  def notify(data) do
    handle_notify(data)
    data
  end

  defp handle_notify({:ok, %{transaction: %Transfer{} = transfer}}) do
    %{from_user: from, to_user: to, amount: amount} =
      Repo.preload(transfer, [:from_user, :to_user])

    notify_received_transfer(from, to, amount)
    notify_sent_transfer(from, to, amount)
  end

  defp handle_notify({:ok, %{transaction: %Withdraw{} = withdraw}}) do
    %{user: user} = Repo.preload(withdraw, :user)

    body = """
    Your withdraw of #{Money.format(withdraw.amount, prefix: "R$")} was executed sucessfully.\
    """

    send_email(user, "withdraw executed successfuly", body)
  end

  defp handle_notify(_), do: :ok

  def notify_received_transfer(from, to, amount) do
    body = """
    You received a transfer of #{Money.format(amount, prefix: "R$")} from #{from.name}.\
    """

    send_email(to, "You received a trasnfer!", body)
  end

  def notify_sent_transfer(from, to, amount) do
    body = """
    Your transfer of #{Money.format(amount, prefix: "R$")} to #{to.name} was finished successfully.\
    """

    send_email(from, "Transfer finished successfully!", body)
  end

  defp send_email(to, subject, body) do
    IO.puts("SENDING EMAIL")

    """
    from: suport@bankingapi.com
    to: #{to.email}
    subject: #{subject}

    Hello, #{to.name}

    #{body}

    Thank you,
    Banking Api Team
    """
    |> IO.puts()
  end
end
