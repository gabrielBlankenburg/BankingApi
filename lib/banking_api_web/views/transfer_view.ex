defmodule BankingApiWeb.TransferView do
  use BankingApiWeb, :view
  alias BankingApiWeb.TransferView
  alias BankingApiWeb.UserView

  def render("show.json", params) do
    Enum.reduce(params, %{}, &format_show_item/2)
  end

  def render("transfer.json", %{transfer: transfer}) do
    %{id: transfer.id, amount: transfer.amount}
  end

  defp format_show_item({:message, message}, content) do
    Map.put(content, :message, message)
  end

  defp format_show_item({:user, user}, content) do
    Map.put(content, :user, render_one(user, UserView, "user.json"))
  end

  defp format_show_item({:transfer, transfer}, content) do
    Map.put(content, :transfer, render_one(transfer, TransferView, "transfer.json"))
  end

  defp format_show_item(_, content), do: content
end
