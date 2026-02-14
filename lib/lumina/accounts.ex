defmodule Lumina.Accounts do
  use Ash.Domain, otp_app: :lumina, extensions: [AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource Lumina.Accounts.Token
    resource Lumina.Accounts.User
    resource Lumina.Accounts.OrgMembership
    resource Lumina.Accounts.OrgInvite
  end
end
