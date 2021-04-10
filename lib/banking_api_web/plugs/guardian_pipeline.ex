defmodule BankingApiWeb.Plugs.GuardianPipeline do
  @moduledoc """
  Guardian Pipeline so we can plug it into our routes/controllers
  """
  use Guardian.Plug.Pipeline,
    otp_app: :banking_api,
    error_handler: BankingApiWeb.Plugs.GuardianErrorHandler,
    module: BankingApi.Accounts.Guardian

  plug Guardian.Plug.VerifySession, claims: %{"typ" => "access"}
  plug Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"}
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource
end
