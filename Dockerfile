FROM elixir:latest

WORKDIR /app

RUN mix local.hex --force && \
    mix archive.install hex phx_new 1.5.8 --force && \
    mix local.rebar --force

COPY mix.exs .
COPY mix.lock .

CMD ./entrypoint.sh
