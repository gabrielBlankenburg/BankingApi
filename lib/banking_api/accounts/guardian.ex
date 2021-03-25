defmodule BankingApi.Accounts.Guardian do
  @moduledoc """
  The implementations module for `Guardian`. It generates the token and get its claims
  """
  use Guardian, otp_app: :banking_api
  alias BankingApi.Accounts

  # Public API

  def authenticate(user) do
    {:ok, token, _claims} = __MODULE__.encode_and_sign(user)
    {:ok, token}
  end

  # Callback API

  @impl true
  def subject_for_token(user, _claims) do
    sub = to_string(user.id)
    {:ok, sub}
  end

  @impl true
  @spec resource_from_claims(map) :: {:ok, any}
  def resource_from_claims(claims) do
    user =
      claims
      |> Map.get("sub")
      |> Accounts.get_user!()

    {:ok, user}
  end

  @impl true
  def build_claims(claims, %{profile: profile}, _) do
    {:ok, Map.put(claims, :profile, profile)}
  end
end
