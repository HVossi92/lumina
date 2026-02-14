defmodule Lumina.Slugs do
  @moduledoc """
  Pure helpers for generating URL-friendly slugs from strings.
  """

  @doc """
  Converts a string to a URL-friendly slug: lowercase, alphanumeric and hyphens only.

  ## Examples

      iex> Lumina.Slugs.slugify("My Org")
      "my-org"

      iex> Lumina.Slugs.slugify("  Hello  World  ")
      "hello-world"

      iex> Lumina.Slugs.slugify("")
      ""

      iex> Lumina.Slugs.slugify(nil)
      ""
  """
  @spec slugify(String.t() | nil) :: String.t()
  def slugify(nil), do: ""
  def slugify(""), do: ""

  def slugify(string) when is_binary(string) do
    string
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s-]/, "")
    |> String.replace(~r/\s+/, "-")
    |> String.trim("-")
  end
end
