defmodule LuminaWeb.JoinLive do
  @moduledoc """
  Join an organization via invite link or code.
  Requires authentication; redirects to sign-in with return_to if not logged in.
  """
  use LuminaWeb, :live_view

  require Ash.Query
  alias Lumina.Accounts.OrgInvite

  @impl true
  def mount(params, _session, socket) do
    user = socket.assigns.current_user
    token = params["token"]

    cond do
      is_nil(user) ->
        return_to = if token, do: "/join/#{token}", else: "/join"

        {:halt,
         socket
         |> put_flash(:info, "Sign in to join an organization")
         |> Phoenix.LiveView.redirect(to: "/sign-in?return_to=#{URI.encode_www_form(return_to)}")}

      token ->
        # Landed from link with token - try to redeem or show form
        handle_token(socket, token, user)

      true ->
        # No token - show form to enter code
        {:ok,
         assign(socket,
           form: to_form(%{"token" => ""}, as: "join"),
           invite: nil,
           error: nil,
           page_title: "Join Organization"
         )}
    end
  end

  defp handle_token(socket, token, _user) do
    case fetch_invite(token) do
      {:ok, invite} ->
        if expired?(invite) do
          {:ok,
           assign(socket,
             invite: nil,
             error: "This invite has expired",
             form: to_form(%{"token" => token}, as: "join"),
             page_title: "Expired Invite"
           )}
        else
          {:ok,
           assign(socket,
             invite: invite,
             token: token,
             form: to_form(%{"token" => token}, as: "join"),
             error: nil,
             page_title: "Join #{invite.org.name}"
           )}
        end

      {:error, _} ->
        {:ok,
         assign(socket,
           invite: nil,
           error: "Invalid or expired invite",
           form: to_form(%{"token" => token}, as: "join"),
           page_title: "Invalid Invite"
         )}
    end
  end

  defp fetch_invite(token) do
    case OrgInvite
         |> Ash.Query.for_read(:read)
         |> Ash.Query.filter(token: token)
         |> Ash.read(authorize?: false) do
      {:ok, [invite | _]} ->
        invite = Ash.load!(invite, :org, authorize?: false)
        {:ok, invite}

      {:ok, []} ->
        {:error, :not_found}

      {:error, _} ->
        {:error, :not_found}
    end
  end

  defp expired?(invite) do
    DateTime.compare(invite.expires_at, DateTime.utc_now()) == :lt
  end

  defp extract_token(input) do
    input = String.trim(input)

    if String.contains?(input, "/join/") do
      input |> String.split("/join/") |> List.last() |> String.trim()
    else
      input
    end
  end

  @impl true
  def handle_event("validate", %{"join" => %{"token" => token}}, socket) do
    if String.trim(token) == "" do
      {:noreply, assign(socket, form: to_form(%{"token" => token}, as: "join"), invite: nil)}
    else
      case fetch_invite(extract_token(token)) do
        {:ok, invite} ->
          {:noreply,
           assign(socket,
             form: to_form(%{"token" => token}, as: "join"),
             invite: if(expired?(invite), do: nil, else: invite),
             error: if(expired?(invite), do: "This invite has expired", else: nil)
           )}

        {:error, _} ->
          {:noreply,
           assign(socket,
             form: to_form(%{"token" => token}, as: "join"),
             invite: nil,
             error: "Invalid or expired invite"
           )}
      end
    end
  end

  def handle_event("redeem", %{"join" => %{"token" => token}}, socket) do
    user = socket.assigns.current_user
    token = extract_token(token)

    case OrgInvite.redeem(token, actor: user) do
      {:ok, %{org: org, already_member: _}} ->
        {:noreply,
         socket
         |> put_flash(:info, "You have joined #{org.name}")
         |> push_navigate(to: ~p"/orgs/#{org.slug}")}

      {:error, error} ->
        message = Exception.message(error)

        {:noreply,
         socket
         |> put_flash(:error, message)
         |> assign(error: message)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section>
      <h1 class="text-3xl font-serif font-bold text-base-content mb-6 text-balance">
        Join Organization
      </h1>

      <%= if @error do %>
        <div class="mb-6 alert alert-error rounded-md">
          <.icon name="hero-exclamation-circle" class="size-5 shrink-0" />
          <span>{@error}</span>
        </div>
      <% end %>

      <%= if @invite do %>
        <div class="mb-6 p-6 rounded-md border border-base-300 bg-base-200">
          <h2 class="text-lg font-serif font-semibold text-base-content">You're invited to join</h2>
          <p class="mt-2 text-2xl font-serif font-bold text-accent">{@invite.org.name}</p>
          <.form for={@form} id="join-form" phx-submit="redeem" phx-change="validate" class="mt-6">
            <input type="hidden" name="join[token]" value={@form.params["token"]} />
            <button type="submit" class="btn btn-accent rounded-md">
              Join Organization
            </button>
          </.form>
        </div>
      <% else %>
        <.form for={@form} id="join-form" phx-submit="redeem" phx-change="validate" class="space-y-6">
          <div class="form-control">
            <.input
              field={@form[:token]}
              type="text"
              label="Invite code or paste the full invite link"
              placeholder="Paste your invite code or link here"
            />
            <p class="mt-2 text-sm text-base-content/40">
              Enter the code shared by your administrator, or paste the full invite URL.
            </p>
          </div>
          <div class="flex justify-end">
            <button type="submit" class="btn btn-accent rounded-md">
              Join
            </button>
          </div>
        </.form>
      <% end %>

      <.link navigate={~p"/"} class="mt-6 inline-block btn btn-ghost btn-sm rounded-md">
        ← Back to dashboard
      </.link>
    </section>
    """
  end
end
