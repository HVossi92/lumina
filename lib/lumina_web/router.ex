defmodule LuminaWeb.Router do
  use LuminaWeb, :router

  import Oban.Web.Router
  use AshAuthentication.Phoenix.Router

  import AshAuthentication.Plug.Helpers

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug LuminaWeb.Plugs.StoreRequestPath
    plug LuminaWeb.Plugs.StoreReturnTo
    plug :fetch_live_flash
    plug :put_root_layout, html: {LuminaWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :load_from_session
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :load_from_bearer
    plug :set_actor, :user
  end

  scope "/", LuminaWeb do
    pipe_through :browser

    # Public share link route (no auth required)
    live "/share/:token", ShareLive.Show

    # Admin backup download endpoint
    get "/admin/backup/download/:filename", AdminController, :download_backup

    ash_authentication_live_session :authenticated_routes,
      layout: {LuminaWeb.Layouts, :app},
      on_mount: [
        {LuminaWeb.LiveUserAuth, :live_user_required},
        {LuminaWeb.LiveUserAuth, :assign_current_path},
        {LuminaWeb.LiveUserAuth, :assign_sidebar_albums},
        {LuminaWeb.LiveUserAuth, :assign_org_storage}
      ] do
      live "/", DashboardLive
      live "/join", JoinLive
      live "/join/:token", JoinLive
      live "/orgs/new", OrgLive.New
      live "/orgs/:org_slug", OrgLive.Show
      live "/orgs/:org_slug/albums/new", AlbumLive.New
      live "/orgs/:org_slug/albums/:album_id", AlbumLive.Show
      live "/orgs/:org_slug/albums/:album_id/upload", PhotoLive.Upload
      live "/orgs/:org_slug/albums/:album_id/share", AlbumLive.Share
      live "/admin/backup", AdminLive.Backup
      live "/admin/orgs", AdminLive.Orgs
    end
  end

  scope "/", LuminaWeb do
    pipe_through :browser

    auth_routes AuthController, Lumina.Accounts.User, path: "/auth"
    sign_out_route AuthController

    # Remove these if you'd like to use your own authentication views
    sign_in_route register_path: "/register",
                  reset_path: "/reset",
                  auth_routes_prefix: "/auth",
                  on_mount: [{LuminaWeb.LiveUserAuth, :live_no_user}],
                  overrides: [
                    Elixir.AshAuthentication.Phoenix.Overrides.DaisyUI,
                    LuminaWeb.AuthOverrides
                  ]

    # Remove this if you do not want to use the reset password feature
    reset_route auth_routes_prefix: "/auth",
                overrides: [
                  Elixir.AshAuthentication.Phoenix.Overrides.DaisyUI,
                  LuminaWeb.AuthOverrides
                ]

    # Remove this if you do not use the confirmation strategy
    confirm_route Lumina.Accounts.User, :confirm_new_user,
      auth_routes_prefix: "/auth",
      overrides: [Elixir.AshAuthentication.Phoenix.Overrides.DaisyUI, LuminaWeb.AuthOverrides]

    # Remove this if you do not use the magic link strategy.
    magic_sign_in_route(Lumina.Accounts.User, :magic_link,
      auth_routes_prefix: "/auth",
      overrides: [Elixir.AshAuthentication.Phoenix.Overrides.DaisyUI, LuminaWeb.AuthOverrides]
    )
  end

  # Other scopes may use custom stacks.
  # scope "/api", LuminaWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:lumina, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: LuminaWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end

    scope "/" do
      pipe_through :browser

      oban_dashboard("/oban")
    end
  end

  if Application.compile_env(:lumina, :dev_routes) do
    import AshAdmin.Router

    scope "/admin" do
      pipe_through :browser

      ash_admin "/"
    end
  end
end
