defmodule BankingApiWeb.WithdrawView do
  use BankingApiWeb, :view
  alias BankingApiWeb.WithdrawView
  alias BankingApiWeb.UserView

  def render("show.json", params) do
    Enum.reduce(params, %{}, &format_show_item/2)
  end

  def render("withdraw.json", %{withdraw: withdraw}) do
    %{id: withdraw.id, amount: withdraw.amount}
  end

  defp format_show_item({:message, message}, content) do
    Map.put(content, :message, message)
  end

  defp format_show_item({:user, user}, content) do
    Map.put(content, :user, render_one(user, UserView, "user.json"))
  end

  defp format_show_item({:withdraw, withdraw}, content) do
    Map.put(content, :withdraw, render_one(withdraw, WithdrawView, "withdraw.json"))
  end

  defp format_show_item(_, content), do: content
end
