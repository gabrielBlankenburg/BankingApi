defmodule BankingApiWeb.TransactionReportView do
  use BankingApiWeb, :view
  alias BankingApiWeb.TransactionReportView

  def render("show.json", %{data: [total: total]}) do
    %{
      data: %{
        total: total
      }
    }
  end

  def render("show.json", %{data: data}) do
    %{data: render_many(data, TransactionReportView, "data.json")}
  end

  def render("data.json", %{transaction_report: {date, amount}}) do
    %{date: date, amount: amount}
  end
end
