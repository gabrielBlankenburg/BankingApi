echo "HELOOOOOOOOOO"
cat .env
mix deps.get
mix ecto.setup
mix ecto.create
mix ecto.migrate
mix phx.server
