# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :banking_api,
  ecto_repos: [BankingApi.Repo]

# Configures the endpoint
config :banking_api, BankingApiWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "P1JkEHWdakAiJdmU335F3OiD1iT7KyNPQzWRDHNsOAI9SEDWY1VZxNCzWLAi3nqJ",
  render_errors: [view: BankingApiWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: BankingApi.PubSub,
  live_view: [signing_salt: "PCVFKjAx"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :banking_api, BankingApi.Accounts.Guardian,
  issuer: "banking_api",
  secret_key: "/9zknaZ4BAaJH6wtDY56XSGmckOgIEIlw0FlNHiHPMopSp0qBLnm/8LzjzsZV1dM"

config :banking_api, BankingApiWeb.Plugs.AuthAccessPipeline,
  module: BankingApiWeb.Plugs.Authenticate,
  error_handler: BankingApiWeb.Plugs.ErrorHandler

config :banking_api, env: Mix.env()
# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
