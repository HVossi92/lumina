defmodule Lumina.Jobs.ProcessUpload do
  use Oban.Worker,
    queue: :media,
    max_attempts: 3

  alias Lumina.Media.{Photo, Thumbnail}

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"photo_id" => photo_id}}) do
    # Use Repo.get! to bypass multitenancy for background job context
    photo = Lumina.Repo.get!(Photo, photo_id)

    case Thumbnail.generate(photo.original_path, photo.thumbnail_path) do
      {:ok, _path} ->
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end
end
