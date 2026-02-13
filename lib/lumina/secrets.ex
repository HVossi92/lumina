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
end
