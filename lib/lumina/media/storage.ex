defmodule Lumina.Media.Storage do
  @moduledoc """
  Helpers for org storage (e.g. sum of photo file sizes).
  AshSqlite does not support resource aggregates, so we compute via Ecto.
  """
  import Ecto.Query
  alias Lumina.Repo

  @doc """
  Returns total bytes used by photos in the given org (sum of file_size).
  """
  def used_bytes(org_id) do
    from(p in "photos", where: p.org_id == ^org_id, select: coalesce(sum(p.file_size), 0))
    |> Repo.one!()
  end
end
