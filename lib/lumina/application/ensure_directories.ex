defmodule Lumina.Application.EnsureDirectories do
  @moduledoc """
  Ensures required directory structures exist at application startup.
  Creates priv/static/uploads and its originals/ and thumbnails/ subdirectories
  so that backup and photo uploads work in all environments.
  """
  require Logger

  @uploads_subdirs ~w(originals thumbnails)

  @doc """
  Ensures all required directories exist.
  Called during application startup.
  Returns :ok regardless of success to allow app to start.
  """
  def init do
    base = Application.app_dir(:lumina, "priv/static/uploads")

    Enum.each([base | Enum.map(@uploads_subdirs, &Path.join(base, &1))], fn path ->
      ensure_directory(path)
    end)

    :ok
  end

  defp ensure_directory(path) do
    case File.mkdir_p(path) do
      :ok ->
        Logger.info("Ensured directory: #{path}")
        :ok

      {:error, reason} ->
        Logger.warning("Failed to create directory #{path}: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
