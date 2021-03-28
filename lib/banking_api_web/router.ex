defmodule BankingApiWeb.Router do
  use BankingApiWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :admin_profile_api do
    plug :accepts, ["json"]
    plug BankingApiWeb.Plugs.GuardianPipeline
    plug BankingApiWeb.Plugs.AuthorizeProfile, :admin
  end

  pipeline :user_profile_api do
    plug :accepts, ["json"]
    plug BankingApiWeb.Plugs.GuardianPipeline
    plug BankingApiWeb.Plugs.AuthorizeProfile, :user
  end

  scope "/api", BankingApiWeb do
    pipe_through :api
    post "/register", LoginController, :register
    post "/login", LoginController, :login
  end

  scope "/api", BankingApiWeb do
    pipe_through :user_profile_api
    post "/withdrawal", WithdrawalController, :create
  end

  scope "/api/admin", BankingApiWeb do
    pipe_through :admin_profile_api
    resources "/users", UserController, except: [:new, :edit]
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through [:fetch_session, :protect_from_forgery]
      live_dashboard "/dashboard", metrics: BankingApiWeb.Telemetry
    end
  end
end
