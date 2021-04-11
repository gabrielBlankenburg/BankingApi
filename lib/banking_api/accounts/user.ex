defmodule BankingApi.Accounts.User do
  @moduledoc """
  User Schema
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :balance, :integer
    field :email, :string
    field :name, :string
    field :password_hash, :string
    field :profile, Ecto.Enum, values: [:admin, :user]
    field :password, :string, virtual: true
    timestamps()
  end

  @doc false
  def create_changeset(user, attrs) do
    user
    |> changeset(attrs)
    |> validate_required([:password])
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :password, :profile, :balance])
    |> validate_required([:email, :name, :profile, :balance])
    |> validate_format(:email, ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
    |> unique_constraint(:email)
    |> put_password_hash
    |> validate_number(:balance, greater_than_or_equal_to: 0)
  end

  defp put_password_hash(
         %Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset
       ) do
    change(changeset, Bcrypt.add_hash(password))
  end

  defp put_password_hash(changeset), do: changeset
end
