defmodule LuminaWeb.AdminSignInLive do
  @moduledoc """
  Admin-only sign-in: password sign-in form only. No register form, no Google.
  Renders SignInForm directly so the register form is never in the DOM.
  """
  use LuminaWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    strategy = AshAuthentication.Info.strategy!(Lumina.Accounts.User, :password)
    overrides = [Elixir.AshAuthentication.Phoenix.Overrides.DaisyUI, LuminaWeb.AuthOverrides]

    {:ok,
     socket
     |> assign(:strategy, strategy)
     |> assign(:overrides, overrides)
     |> assign(:page_title, "Admin sign in")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full max-w-sm mx-auto">
      <h1 class="text-2xl font-serif font-bold text-base-content mb-6 tracking-tight">
        Admin sign in
      </h1>
      <.live_component
        module={AshAuthentication.Phoenix.Components.Password.SignInForm}
        id="admin-password-sign-in"
        strategy={@strategy}
        overrides={@overrides}
        auth_routes_prefix="/auth"
        label={false}
      />
    </div>
    """
  end
end
