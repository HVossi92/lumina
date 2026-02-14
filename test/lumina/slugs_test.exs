defmodule Lumina.SlugsTest do
  use ExUnit.Case, async: true

  describe "slugify/1" do
    test "lowercases and replaces spaces with hyphens" do
      assert Lumina.Slugs.slugify("My Org") == "my-org"
    end

    test "trims leading and trailing spaces and hyphens" do
      assert Lumina.Slugs.slugify("  Hello  World  ") == "hello-world"
    end

    test "strips non-alphanumeric except hyphens" do
      assert Lumina.Slugs.slugify("Org! @# Name?") == "org-name"
    end

    test "returns empty string for nil" do
      assert Lumina.Slugs.slugify(nil) == ""
    end

    test "returns empty string for empty string" do
      assert Lumina.Slugs.slugify("") == ""
    end

    test "preserves existing hyphens and numbers" do
      assert Lumina.Slugs.slugify("My-Org 2024") == "my-org-2024"
    end
  end
end
