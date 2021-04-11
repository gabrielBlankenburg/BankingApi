cat .env
mix deps.get
mix ecto.setup
mix ecto.create
mix ecto.migrate
mix run priv/repo/seeds.exs
mix phx.server
