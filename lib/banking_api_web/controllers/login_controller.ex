defmodule BankingApiWeb.LoginController do
  @moduledoc """
  The Login Controller.
  """
  use BankingApiWeb, :controller
  alias BankingApi.Accounts
  alias BankingApi.Accounts.User

  # Represents R$ 1000,00 since float numbers aren't precise
  @initial_balance 100_000

  action_fallback BankingApiWeb.FallbackController

  @doc """
  Only admin users can grant the profile `:admin` to users, as this is a public account creation,
  the ´profile´ can only be ´:user´
  """
  def register(conn, params) do
    user_params =
      params
      |> Map.put("profile", :user)
      |> Map.put("balance", @initial_balance)

    with {:ok, %User{} = user} <- Accounts.create_user(user_params),
         {:ok, token} <- Accounts.login(params["email"], params["password"]) do
      conn
      |> put_status(:created)
      |> render("register.json", token: token, user: user)
    end
  end

  def login(conn, %{"email" => email, "password" => password}) do
    with {:ok, token} <- Accounts.login(email, password) do
      render(conn, "login.json", token: token)
    end
  end
end
