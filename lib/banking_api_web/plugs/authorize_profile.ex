defmodule BankingApiWeb.Plugs.AuthorizeProfile do
  @moduledoc """
  This plug will authorize profiles by their hierarchy, so an `admin` profile can access
  an `user` profile endpoint, but never the opposite
  """
  import Plug.Conn
  alias BankingApi.Accounts.Guardian
  alias BankingApi.Accounts.User

  @accepted_profiles [:admin, :user]

  def init(profile \\ :user) when profile in @accepted_profiles, do: profile

  def call(conn, profile) do
    conn
    |> Guardian.Plug.current_resource()
    |> handle_profile(conn, profile)
  end

  # If the user is admin he may access any endpoint, if he is not an admin, his profile must match with
  # the required one
  defp handle_profile(%User{profile: user_profile, id: id}, conn, profile)
       when user_profile == :admin or profile == user_profile do
    assign(conn, :user_id, id)
  end

  defp handle_profile(_, conn, _) do
    body = Jason.encode!(%{message: "unauthorized"})

    conn
    |> send_resp(403, body)
    |> halt()
  end
end
