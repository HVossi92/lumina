defmodule Lumina.Media.Org.GenerateSlugFromName do
  @moduledoc """
  Ash change: sets slug from name when slug is blank on create.
  Keeps slug generation as resource-level business logic.
  """
  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _context) do
    name = Ash.Changeset.get_attribute(changeset, :name)
    slug = Ash.Changeset.get_attribute(changeset, :slug)

    if blank?(slug) and present?(name) do
      Ash.Changeset.change_attribute(changeset, :slug, Lumina.Slugs.slugify(name))
    else
      changeset
    end
  end

  defp blank?(nil), do: true
  defp blank?(s) when is_binary(s), do: String.trim(s) == ""
  defp blank?(_), do: true

  defp present?(nil), do: false
  defp present?(s) when is_binary(s), do: String.trim(s) != ""
  defp present?(_), do: false
end
