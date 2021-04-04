defmodule BankingApiWeb.TransactionReportController do
  @moduledoc """
  Controller responsible for retrieving reports for transactions.
  """
  use BankingApiWeb, :controller
  alias BankingApi.Reports

  action_fallback BankingApiWeb.FallbackController

  @doc """
  Find for the given period in the given range.
  If `range_start` and `range_end` are provided, they must be strings in the format "yyyy-mm-dd"
  """
  def period(conn, %{
        "period" => period,
        "range_start" => start_string,
        "range_end" => end_string
      }) do
    with {:ok, range_start} <- format_date(start_string),
         {:ok, range_end} <- format_date(end_string),
         {:ok, data} <-
           Reports.get_transaction_report_by_period_in_range(period, range_start, range_end) do
      conn
      |> put_status(:ok)
      |> render("show.json", data: data)
    else
      _ ->
        {:error, :not_found}
    end
  end

  def period(conn, %{"period" => period}) do
    with {:ok, data} <- Reports.get_transaction_report_by_period(period) do
      conn
      |> put_status(:ok)
      |> render("show.json", data: data)
    else
      _ ->
        {:error, :not_found}
    end
  end

  # Gets a date in the format "yyyy-mm-dd" and converts into a Date, returning
  # {:ok, %Date{}} or {:error, reason}
  defp format_date(string) do
    case String.split(string, "-") do
      [year, month, day] ->
        year
        |> String.to_integer()
        |> Date.new(String.to_integer(month), String.to_integer(day))

      _ ->
        {:error, :invalid_date}
    end
  end
end
