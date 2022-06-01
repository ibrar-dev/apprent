defmodule AppCount.Application do
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    Ecto.Migrator.with_repo(
      AppCount.Repo,
      fn repo ->
        Ecto.Migrator.run(repo, :up, all: true)
        repo |> Triplex.all() |> Enum.map(&Triplex.migrate(&1, repo))
      end
    )

    Agent.start(fn -> %{} end, name: :tech_tracking)

    :ok = require_env(AppCount.env())
    AppCount.Crypto.start_crypto_server()

    # Define workers and child supervisors to be supervised
    children =
      [
        AppCount.Repo,
        {Phoenix.PubSub, [name: AppCount.PubSub, adapter: Phoenix.PubSub.PG2]},
        {Registry, keys: :unique, name: AppCount.Registry},
        AppCountWeb.TechPresence,
        AppCount.Core.DomainEventServer,
        AppCountWeb.Endpoint,
        AppCount.UploadServer,
        AppCount.Jobs.Server,
        AppCount.TwilioSupervisor,
        AppCount.YardiSupervisor,
        AppCount.Adapters.SoftLedgerExternalService,
        AppCount.Adapters.ZendeskExternalService,
        AppCount.Tasks.Queue,
        AppCount.Maintenance.InsightReports.ReportManager,
        AppCount.CachesSupervisor,
        AppCount.ObserverSupervisor,
        AppCountAuth.AuthServer,
        AppCount.Initializer
      ] ++
        maybe_dns_server(AppCount.env(:environment), System.get_env("NO_DNS", nil))

    opts = [strategy: :one_for_one, name: AppCount.Supervisor]

    Supervisor.start_link(children, opts)
  end

  def start_phase(:init_data, _start_type, _phase_args) do
    {:ok, _} = AppCount.Accounting.Utils.ReportTemplates.init_templates()
    AppCount.Accounting.SpecialAccounts.init_accounts()
    AppCount.Rewards.Utils.Types.create_default_types()
    :ok
  end

  def maybe_dns_server(:dev, nil) do
    [{AppCount.DevDNS, 21_334}]
  end

  def maybe_dns_server(_env, _) do
    []
  end

  def require_env(%{
        environment: env,
        authorize_env: authorize_env,
        forms_iv: iv,
        rent_apply_key: key,
        socket_path: sock,
        crypto_server_path: path,
        local_crypto_key: local_crypto_key
      })
      when is_atom(env) and is_atom(authorize_env) and
             is_binary(iv) and is_binary(sock) and is_integer(key) and is_binary(path) and
             is_binary(local_crypto_key) do
    :ok
  end

  def require_env(), do: raise("Incomplete Environment Configuration")

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    AppCountWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defimpl Jason.Encoder, for: [MapSet, Range, Stream] do
    def encode(struct, opts) do
      Jason.Encode.list(Enum.to_list(struct), opts)
    end
  end
end
