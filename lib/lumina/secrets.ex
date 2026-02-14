defmodule Lumina.Secrets do
  use AshAuthentication.Secret

  def secret_for(
        [:authentication, :tokens, :signing_secret],
        Lumina.Accounts.User,
        _opts,
        _context
      ) do
    Application.fetch_env(:lumina, :token_signing_secret)
  end

  def secret_for(
        [:authentication, :strategies, :google, key],
        Lumina.Accounts.User,
        _opts,
        _context
      )
      when key in [:client_id, :redirect_uri, :client_secret] do
    opts = Application.get_env(:lumina, :google_oauth, [])

    case Keyword.get(opts, key) do
      nil -> :error
      val -> {:ok, val}
    end
  end
end
