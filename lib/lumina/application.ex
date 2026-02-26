defmodule Lumina.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Lumina.Application.EnsureDirectories.init()

    children = [
      LuminaWeb.Telemetry,
      Lumina.Repo,
      {Ecto.Migrator,
       repos: Application.fetch_env!(:lumina, :ecto_repos), skip: skip_migrations?()},
      {Oban,
       AshOban.config(
         Application.fetch_env!(:lumina, :ash_domains),
         Application.fetch_env!(:lumina, Oban)
       )},
      # Start a worker by calling: Lumina.Worker.start_link(arg)
      # {Lumina.Worker, arg},
      # Start to serve requests, typically the last entry
      {DNSCluster, query: Application.get_env(:lumina, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Lumina.PubSub},
      LuminaWeb.Endpoint,
      {AshAuthentication.Supervisor, [otp_app: :lumina]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Lumina.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LuminaWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations?() do
    # By default, sqlite migrations are run when using a release
    System.get_env("RELEASE_NAME") == nil
  end
end
