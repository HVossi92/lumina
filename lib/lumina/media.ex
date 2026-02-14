defmodule Lumina.Media do
  use Ash.Domain, otp_app: :lumina, extensions: [AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource Lumina.Media.Org
    resource Lumina.Media.Album
    resource Lumina.Media.Photo
    resource Lumina.Media.ShareLink
  end
end
