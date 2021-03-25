defmodule BankingApi.Accounts.User do
  @moduledoc """
  User Schema
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :balance, :integer
    field :email, :string
    field :password_hash, :string
    field :profile, Ecto.Enum, values: [:admin, :user]
    field :password, :string, virtual: true
    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password, :profile, :balance])
    |> validate_required([:email, :password])
    |> unique_constraint(:email)
    |> put_password_hash
  end

  defp put_password_hash(
         %Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset
       ) do
    change(changeset, Bcrypt.add_hash(password))
  end

  defp put_password_hash(changeset), do: changeset
end