defmodule Lumina.Application.EnsureDirectoriesTest do
  use ExUnit.Case, async: false

  alias Lumina.Application.EnsureDirectories

  describe "init/0" do
    test "ensures priv/static/uploads and originals/thumbnails subdirectories exist" do
      base = Application.app_dir(:lumina, "priv/static/uploads")

      assert :ok = EnsureDirectories.init()

      assert File.dir?(base), "expected priv/static/uploads to exist"
      assert File.dir?(Path.join(base, "originals")), "expected originals subdir to exist"
      assert File.dir?(Path.join(base, "thumbnails")), "expected thumbnails subdir to exist"
    end

    test "second call does not error (idempotent)" do
      assert :ok = EnsureDirectories.init()
      assert :ok = EnsureDirectories.init()
    end
  end
end
