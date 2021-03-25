defmodule BankingApiWeb.LoginView do
  use BankingApiWeb, :view
  alias BankingApiWeb.UserView

  def render("login.json", %{token: token}) do
    %{token: token}
  end

  def render("register.json", %{token: token, user: user}) do
    %{
      user: render_one(user, UserView, "user.json"),
      token: token
    }
  end
end
