defmodule BankingApi.CommonFixtures do
  alias BankingApi.Accounts

  @user_attrs %{
    balance: 42,
    email: "user@email.com",
    password: "some password_hash",
    profile: :user
  }
  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(@user_attrs)
      |> Accounts.create_user()

    user
  end
end
