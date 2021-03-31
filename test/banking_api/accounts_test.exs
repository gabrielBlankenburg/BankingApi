defmodule BankingApi.AccountsTest do
  @moduledoc false
  use BankingApi.DataCase
  import BankingApi.CommonFixtures

  alias BankingApi.Accounts

  describe "users" do
    alias BankingApi.Accounts.User

    @valid_attrs %{
      balance: 42,
      email: "some email",
      password: "some password_hash",
      profile: :user
    }
    @update_attrs %{
      balance: 43,
      email: "some updated email",
      password: "some updated password_hash",
      profile: :admin
    }
    @invalid_attrs %{balance: nil, email: nil, password_hash: nil, profile: nil}

    test "list_users/0 returns all users" do
      user =
        user_fixture()
        |> Map.put(:password, nil)

      assert Accounts.list_users() == [user]
    end

    test "get_user/1 returns the user with given id" do
      user = user_fixture()
      assert Accounts.get_user(user.id) == Map.put(user, :password, nil)
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      assert Accounts.get_user!(user.id) == Map.put(user, :password, nil)
    end

    test "create_user/1 with valid data creates a user" do
      assert {:ok, %User{} = user} = Accounts.create_user(@valid_attrs)
      assert user.balance == 42
      assert user.email == "some email"
      refute user.password_hash == "some password_hash"
      assert user.password_hash != nil
      assert user.profile == :user
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()
      assert {:ok, %User{} = user} = Accounts.update_user(user, @update_attrs)
      assert user.balance == 43
      assert user.email == "some updated email"
      refute user.password_hash == "some updated password_hash"
      assert user.password_hash != nil
      assert user.profile == :admin
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, @invalid_attrs)
      assert Map.put(user, :password, nil) == Accounts.get_user!(user.id)
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(user.id) end
    end

    test "change_user/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Accounts.change_user(user)
    end
  end
end
