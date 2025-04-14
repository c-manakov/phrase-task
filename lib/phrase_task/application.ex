defmodule PhraseTask.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PhraseTaskWeb.Telemetry,
      PhraseTask.Repo,
      {DNSCluster, query: Application.get_env(:phrase_task, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: PhraseTask.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: PhraseTask.Finch},
      # Start a worker by calling: PhraseTask.Worker.start_link(arg)
      # {PhraseTask.Worker, arg},
      # Start to serve requests, typically the last entry
      PhraseTaskWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PhraseTask.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PhraseTaskWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
