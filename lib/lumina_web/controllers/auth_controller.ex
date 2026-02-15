defmodule LuminaWeb.AuthController do
  use LuminaWeb, :controller
  use AshAuthentication.Phoenix.Controller

  require Ash.Query
  require Logger

  alias Lumina.Accounts.OrgInvite

  def success(conn, activity, user, _token) do
    return_to = get_session(conn, :return_to) || ~p"/"

    # New users (OAuth signup) are only allowed when they have a valid org invite in return_to
    if oauth_callback?(activity) do
      user_with_memberships = Ash.load!(user, :org_memberships, authorize?: false)
      memberships = user_with_memberships.org_memberships || []

      if memberships == [] do
        case validate_invite_return_to(return_to) do
          :ok ->
            proceed_sign_in(conn, user, return_to, activity)

          :invalid ->
            Ash.destroy(user, authorize?: false)

            conn
            |> clear_session(:lumina)
            |> put_flash(
              :error,
              "You need an invitation to sign up. Use the link from your administrator."
            )
            |> redirect(to: ~p"/sign-in")
        end
      else
        proceed_sign_in(conn, user, return_to, activity)
      end
    else
      proceed_sign_in(conn, user, return_to, activity)
    end
  end

  defp oauth_callback?(activity) do
    case activity do
      {_strategy, :callback} -> true
      _ -> false
    end
  end

  defp validate_invite_return_to(return_to) when is_binary(return_to) do
    token = extract_join_token(return_to)

    cond do
      token == nil or token == "" ->
        :invalid

      true ->
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
  end

  defp validate_invite_return_to(_), do: :invalid

  defp extract_join_token(path) do
    path = path |> String.trim() |> String.split("?") |> List.first()

    if path && String.contains?(path, "/join/") do
      path |> String.split("/join/") |> List.last() |> String.trim()
    else
      nil
    end
  end

  defp proceed_sign_in(conn, user, return_to, activity) do
    message =
      case activity do
        {:confirm_new_user, :confirm} -> "Your email address has now been confirmed"
        {:password, :reset} -> "Your password has successfully been reset"
        _ -> "You are now signed in"
      end

    conn
    |> delete_session(:return_to)
    |> store_in_session(user)
    |> assign(:current_user, user)
    |> put_flash(:info, message)
    |> redirect(to: return_to)
  end

  def failure(conn, activity, reason) do
    Logger.error("Auth failure for #{inspect(activity)}: #{inspect(reason)}")

    message =
      case {activity, reason} do
        {_,
         %AshAuthentication.Errors.AuthenticationFailed{
           caused_by: %Ash.Error.Forbidden{
             errors: [%AshAuthentication.Errors.CannotConfirmUnconfirmedUser{}]
           }
         }} ->
          """
          You have already signed in another way, but have not confirmed your account.
          You can confirm your account using the link we sent to you, or by resetting your password.
          """

        {{:google, _phase}, _} ->
          "Could not sign in with Google. Please try again."

        _ ->
          "Incorrect email or password"
      end

    conn
    |> put_flash(:error, message)
    |> redirect(to: ~p"/sign-in")
  end

  def sign_out(conn, _params) do
    return_to = get_session(conn, :return_to) || ~p"/"

    conn
    |> clear_session(:lumina)
    |> put_flash(:info, "You are now signed out")
    |> redirect(to: return_to)
  end
end
