defmodule AppCount.ReleaseTasks do
  alias Ecto.Migrator
  alias AppCount.Repo

  @otp_app :app_count
  @start_apps [:logger, :ssl, :postgrex, :ecto]

  def migrate do
    init(@otp_app, @start_apps)

    run_migrations_for(@otp_app)

    stop()
  end

  def rollback do
    if AppCount.env()[:environment] == :prod do
      raise "No rollbacks in production!"
    end

    init(@otp_app, @start_apps)

    run_rollbacks_for(@otp_app)

    stop()
  end

  def seed do
    init(@otp_app, @start_apps)

    "#{seed_path(@otp_app)}/*.exs"
    |> Path.wildcard()
    |> Enum.sort()
    |> Enum.each(&run_seed_script/1)

    stop()
  end

  def create do
    Repo.__adapter__().storage_up(Repo.config())
  end

  defp init(_, start_apps) do
    Enum.each(start_apps, &Application.ensure_all_started/1)

    AppCount.Repo.start_link(pool_size: 10)
  end

  defp stop do
    IO.puts("Success!")
    :init.stop()
  end

  defp run_migrations_for(app) do
    IO.puts("Running migrations for #{app}")

    Migrator.run(AppCount.Repo, Migrator.migrations_path(AppCount.Repo), :up, all: true)
  end

  defp run_rollbacks_for(app) do
    IO.puts("Rolling back #{app}")

    Migrator.run(AppCount.Repo, Migrator.migrations_path(AppCount.Repo), :down, step: 1)
  end

  defp run_seed_script(seed_script) do
    IO.puts("Running seed script #{seed_script}..")
    Code.eval_file(seed_script)
  end

  defp seed_path(app), do: priv_dir(app, ["repo", "seeds"])

  defp priv_dir(app, path) when is_list(path) do
    case :code.priv_dir(app) do
      priv_path when is_list(priv_path) or is_binary(priv_path) ->
        Path.join([priv_path] ++ path)

      {:error, :bad_name} ->
        raise ArgumentError, "unknown application: #{inspect(app)}"
    end
  end
end
