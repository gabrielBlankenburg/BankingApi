defmodule BankingApiWeb.WithdrawalView do
  use BankingApiWeb, :view
  alias BankingApiWeb.WithdrawalView
  alias BankingApiWeb.UserView

  def render("show.json", params) do
    Enum.reduce(params, %{}, &format_show_item/2)
  end

  def render("withdrawal.json", %{withdrawal: withdrawal}) do
    %{id: withdrawal.id, amount: withdrawal.amount}
  end

  defp format_show_item({:message, message}, content) do
    Map.put(content, :message, message)
  end

  defp format_show_item({:user, user}, content) do
    Map.put(content, :user, render_one(user, UserView, "user.json"))
  end

  defp format_show_item({:withdrawal, withdrawal}, content) do
    Map.put(content, :withdrawal, render_one(withdrawal, WithdrawalView, "withdrawal.json"))
  end

  defp format_show_item(_, content), do: content
end
