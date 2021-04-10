defmodule BankingApi.Money do
  @moduledoc """
  A helper to handle the money format.
  """

  @doc """
  Receives an integer amount and opts, returning the amount with the separator and prefix.
  The available options are:
  - Prefix: a string to be the resulting prefix, useful for show a currency symbol.
  - Separator: a string that will reparate the floating values.

  ## Examples
  
    iex> format(10_000, prefix: "R$")
    "R$1000,00"

  """
  def format(amount, opts \\ []) do
    opts =
      [separator: ".", prefix: ""]
      |> Keyword.merge(opts)

    separator = Keyword.get(opts, :separator)
    prefix = Keyword.get(opts, :prefix)

    amount
    |> Integer.to_string()
    |> String.split_at(-2)
    |> Tuple.to_list()
    |> Enum.join(separator)
    |> String.replace_prefix("", prefix)
  end
end
