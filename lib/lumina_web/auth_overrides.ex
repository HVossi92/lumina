defmodule LuminaWeb.AuthOverrides do
  @moduledoc """
  Overrides for AshAuthentication Phoenix UI to match Lumina style guide.
  Use with Elixir.AshAuthentication.Phoenix.Overrides.DaisyUI; list this module
  last in the overrides list so these values take precedence.
  """
  use AshAuthentication.Phoenix.Overrides

  alias AshAuthentication.Phoenix.Components

  # Lumina branding on auth pages
  override Components.Banner do
    set :text, "Lumina"
    set :image_url, nil
    set :dark_image_url, nil
    set :href_url, "/"
    set :text_class, "font-serif font-bold text-base-content"
  end

  # Primary actions use accent (golden) to match the rest of the app
  override Components.Password.Input do
    set :submit_class, "btn btn-accent btn-block mt-4 mb-4 rounded-md"

    set :input_class,
        "input input-bordered input-sm bg-base-200/60 border-base-300 text-base-content rounded-md w-full mt-2 mb-2"

    set :input_class_with_error,
        "input input-bordered input-sm input-error bg-base-200/60 border-base-300 text-base-content rounded-md w-full mt-2 mb-2"

    set :checkbox_label_class, "text-sm font-medium text-base-content"
  end

  override Components.Password.SignInForm do
    set :label_class, "mt-2 mb-4 text-2xl font-serif font-bold text-base-content tracking-tight"
  end

  override Components.Password.RegisterForm do
    set :label_class, "mt-2 mb-4 text-2xl font-serif font-bold text-base-content tracking-tight"
  end

  override Components.Password.ResetForm do
    set :label_class, "mt-2 mb-4 text-2xl font-serif font-bold text-base-content tracking-tight"
  end

  override Components.Confirm.Input do
    set :submit_class, "btn btn-accent btn-block mt-4 mb-4 rounded-md"
  end

  override Components.MagicLink do
    set :label_class, "mt-2 mb-4 text-2xl font-serif font-bold text-base-content tracking-tight"
  end

  override Components.MagicLink.Input do
    set :submit_class, "btn btn-accent btn-block mt-4 mb-4 rounded-md"
    set :checkbox_label_class, "text-sm font-medium text-base-content"
  end

  override Components.Reset.Form do
    set :label_class, "mt-2 mb-4 text-2xl font-serif font-bold text-base-content tracking-tight"
  end

  override Components.Flash do
    set :message_class_info,
        "fixed top-2 right-2 mr-2 w-80 sm:w-96 z-50 rounded-md p-3 text-sm alert alert-info"

    set :message_class_error,
        "fixed top-2 right-2 mr-2 w-80 sm:w-96 z-50 rounded-md p-3 text-sm alert alert-error"
  end
end
