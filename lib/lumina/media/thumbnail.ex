defmodule Lumina.Media.Thumbnail do
  @moduledoc """
  Handles thumbnail generation for uploaded photos using libvips.
  """

  @thumbnail_size 400
  @quality 85

  @doc """
  Generate a thumbnail from the source image.

  ## Examples

      iex> generate("/path/to/original.jpg", "/path/to/thumb.jpg")
      {:ok, "/path/to/thumb.jpg"}
  """
  def generate(source_path, dest_path) do
    with {:ok, image} <- Vix.Vips.Image.new_from_file(source_path),
         {:ok, resized} <- resize_image(image),
         :ok <- write_image(resized, dest_path) do
      {:ok, dest_path}
    else
      {:error, reason} ->
        {:error, "Thumbnail generation failed: #{inspect(reason)}"}
    end
  end

  defp resize_image(image) do
    width = Vix.Vips.Image.width(image)
    height = Vix.Vips.Image.height(image)

    # Calculate scale to fit within thumbnail size
    scale = @thumbnail_size / max(width, height)

    # Only resize if image is larger than thumbnail size
    if scale < 1.0 do
      Vix.Vips.Operation.resize(image, scale)
    else
      {:ok, image}
    end
  end

  defp write_image(image, dest_path) do
    # Ensure directory exists
    dest_path
    |> Path.dirname()
    |> File.mkdir_p!()

    opts = write_opts_for(dest_path)
    Vix.Vips.Image.write_to_file(image, dest_path, opts)
  end

  defp write_opts_for(path) do
    case Path.extname(path) |> String.downcase() do
      ext when ext in [".jpg", ".jpeg"] -> [Q: @quality]
      ".webp" -> [Q: @quality]
      ".png" -> [compression: 9]
      _ -> []
    end
  end

  @doc """
  Generate thumbnail path for a photo.
  """
  def thumbnail_path(photo_id, filename) do
    ext = Path.extname(filename)
    Path.join(["priv", "static", "uploads", "thumbnails", "#{photo_id}#{ext}"])
  end

  @doc """
  Generate original path for a photo.
  """
  def original_path(photo_id, filename) do
    ext = Path.extname(filename)
    Path.join(["priv", "static", "uploads", "originals", "#{photo_id}#{ext}"])
  end

  @doc """
  Get public URL path for thumbnail from the stored thumbnail_path.

  Converts a filesystem path like `priv/static/uploads/thumbnails/uuid.ext`
  to a public URL like `/uploads/thumbnails/uuid.ext`.
  """
  def thumbnail_url_from_path(thumbnail_path) do
    path_to_url(thumbnail_path)
  end

  @doc """
  Get public URL path for original from the stored original_path.

  Converts a filesystem path like `priv/static/uploads/originals/uuid.ext`
  to a public URL like `/uploads/originals/uuid.ext`.
  """
  def original_url_from_path(original_path) do
    path_to_url(original_path)
  end

  @doc """
  Get public URL path for thumbnail.
  """
  def thumbnail_url(photo_id, filename) do
    ext = Path.extname(filename)
    "/uploads/thumbnails/#{photo_id}#{ext}"
  end

  @doc """
  Get public URL path for original.
  """
  def original_url(photo_id, filename) do
    ext = Path.extname(filename)
    "/uploads/originals/#{photo_id}#{ext}"
  end

  defp path_to_url(path) do
    # Normalize path separators (e.g. Windows backslashes)
    path = String.replace(path, "\\", "/")

    # Strip everything up to and including "priv/static" (handles relative and absolute paths)
    url_path =
      case String.split(path, "priv/static", parts: 2) do
        [_, rest] -> rest
        [_] -> path
      end

    # Ensure root-relative URL always starts with /
    url_path = String.trim_leading(url_path, "/")
    "/" <> url_path
  end
end
