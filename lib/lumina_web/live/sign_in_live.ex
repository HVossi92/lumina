defmodule LuminaWeb.SignInLive do
  @moduledoc """
  Invite-gated sign-in: shows invite code form until user has a valid invite,
  then shows only "Sign in with Google".
  """
  use LuminaWeb, :live_view

  require Ash.Query
  alias Lumina.Accounts.OrgInvite

  @impl true
  def mount(_params, session, socket) do
    return_to = session["return_to"]
    has_valid_invite = validate_invite_return_to(return_to) == :ok

    {:ok,
     socket
     |> assign(:has_valid_invite, has_valid_invite)
     |> assign(:return_to, return_to)
     |> assign(:form, to_form(%{"token" => ""}, as: "invite"))
     |> assign(:error, nil)
     |> assign(:page_title, "Sign in")}
  end

  @impl true
  def handle_event("validate_invite", %{"invite" => %{"token" => token}}, socket) do
    token = extract_token(String.trim(token))

    if token == "" do
      {:noreply,
       assign(socket,
         form: to_form(%{"token" => socket.assigns.form.params["token"]}, as: "invite"),
         error: nil,
         has_valid_invite: false
       )}
    else
      case validate_invite_token(token) do
        :ok ->
          return_to = "/join/#{token}"

          {:noreply,
           socket
           |> put_flash(:info, "Invite accepted. Sign in with Google to continue.")
           |> redirect(to: "/sign-in?return_to=#{URI.encode_www_form(return_to)}")}

        :invalid ->
          {:noreply,
           assign(socket,
             form: to_form(socket.assigns.form.params, as: "invite"),
             error: "Invalid or expired invite",
             has_valid_invite: false
           )}
      end
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full max-w-sm mx-auto">
      <%= if @has_valid_invite do %>
        <div class="space-y-6">
          <p class="text-base-content/80 text-sm">
            You have a valid invite. Sign in with Google to join the organization.
          </p>
          <a
            href="/auth/user/google"
            class="btn btn-accent btn-block rounded-md gap-2"
            id="sign-in-with-google"
          >
            <.icon name="hero-envelope" class="size-5" /> Sign in with Google
          </a>
        </div>
      <% else %>
        <.form
          for={@form}
          id="invite-form"
          phx-submit="validate_invite"
          class="space-y-6"
        >
          <%= if @error do %>
            <div class="alert alert-error rounded-md text-sm">
              <.icon name="hero-exclamation-circle" class="size-5 shrink-0" />
              <span>{@error}</span>
            </div>
          <% end %>
          <div class="form-control">
            <.input
              field={@form[:token]}
              type="text"
              label="Invite code or paste the full invite link"
              placeholder="Paste your invite code or link here"
            />
            <p class="mt-2 text-sm text-base-content/60">
              Enter the code shared by your administrator, or paste the full invite URL. You need an invite to sign up.
            </p>
          </div>
          <button type="submit" class="btn btn-accent btn-block rounded-md">
            Continue
          </button>
        </.form>
      <% end %>
    </div>
    """
  end

  defp validate_invite_return_to(nil), do: :invalid

  defp validate_invite_return_to(return_to) when is_binary(return_to) do
    token = extract_join_token(return_to)
    validate_invite_token(token)
  end

  defp validate_invite_token(nil), do: :invalid
  defp validate_invite_token(""), do: :invalid

  defp validate_invite_token(token) do
    case OrgInvite
         |> Ash.Query.for_read(:read)
         |> Ash.Query.filter(token: token)
         |> Ash.read(authorize?: false) do
      {:ok, [invite | _]} ->
        if DateTime.compare(invite.expires_at, DateTime.utc_now()) == :lt do
          :invalid
        else
          :ok
        end

      _ ->
        :invalid
    end
  end

  defp extract_join_token(path) do
    path = path |> String.trim() |> String.split("?") |> List.first()

    if path && String.contains?(path, "/join/") do
      path |> String.split("/join/") |> List.last() |> String.trim()
    else
      nil
    end
  end

  defp extract_token(input) do
    if String.contains?(input, "/join/") do
      input |> String.split("/join/") |> List.last() |> String.trim()
    else
      input
    end
  end
end
