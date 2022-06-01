defmodule AppCount.Mixfile do
  use Mix.Project
  @test_envs [:test, :integration]

  def project do
    [
      app: :app_count,
      version: "0.2.0",
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [
        tool: ExCoveralls
      ],
      test_paths: test_paths(Mix.env()),
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.integration": :integration,
        "coveralls.integration.html": :integration,
        "coveralls.html": :test,
        test_coverage: :test,
        "test.with_external": :test,
        "test.all": :test,
        "test.failfast": :test,
        "test.external": :test,
        "test.no_slow": :test,
        "test.show_slow": :test,
        "test.integration": :integration,
        "test.accept": :test
      ],
      dialyzer: [
        plt_add_apps: [:mix]
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {AppCount.Application, []},
      start_phases: [init_data: []],
      extra_applications: [:logger, :runtime_tools, :pdf_generator, :scrivener_ecto, :honeybadger]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support", "test/unit/support"]
  defp elixirc_paths(:integration), do: ["lib", "test/support", "test/integration/support"]
  defp elixirc_paths(:prod), do: ["lib"]
  defp elixirc_paths(_), do: ["lib", "dev"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:bamboo, "~> 2.1.0"},
      {:bamboo_smtp, "~> 4.0.1"},
      {:bamboo_phoenix, "~> 1.0"},
      {:barlix, "~> 0.6.0"},
      {:bcrypt_elixir, "~> 2.1.0"},
      {:benchee, "~> 1.0.1", only: :dev},
      {:bypass, github: "pspdfkit-labs/bypass", only: @test_envs},
      {:cors_plug, "~> 2.0.2"},
      {:credo, "~> 1.5.3", only: [:dev, :test, :integration], runtime: false},
      {:csv, "~> 2.3.1"},
      {:dialyxir, "~> 1.1.0", only: [:dev], runtime: false},
      {:dns, "~> 2.1.0", only: :dev},
      #  The latest is {:decimal, "~> 2.0.0"},  # but requires code changes
      {:decimal, "~> 1.9.0"},
      {:ecto_materialized_path, ">=0.0.0"},
      # ecto_sql above 3.4.5 will break ecto_materialized_path
      {:ecto_sql, "3.4.5"},
      {:elixlsx, git: "https://github.com/Joeman29/elixlsx.git"},
      {:ex_aws, "~> 2.1"},
      {:ex_aws_s3, "~> 2.0"},
      {:ex_crypto, github: "ntrepid8/ex_crypto"},
      {:ex_machina, "~> 2.4", only: @test_envs},
      {:excoveralls, "~> 0.10", only: @test_envs},
      {:external_service, "~> 1.0.1"},
      {:floki, "~> 0.30.0"},
      {:gettext, "~> 0.18.2"},
      {:goth, "~> 1.2.0"},
      {:honeybadger, "~> 0.7"},
      {:httpoison, "~> 1.8.0"},
      {:jason, "~> 1.1"},
      {:logger_file_backend, ">=0.0.0"},
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false},
      {:mock, "~> 0.3.0", only: :test},
      # https://hexdocs.pm/morphix/Morphix.html
      # {:ok, new_data} = Morphix.atomorphiform(data)
      {:morphix, "~> 0.8.0"},
      {:pdf_generator, ">=0.5.5"},
      {:phoenix, "~> 1.5.3"},
      {:phoenix_ecto, "~> 4.0"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_dashboard, "~> 0.4.0"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.15.4"},
      {:phoenix_pubsub, "~> 2.0"},
      {:plug_cowboy, "~> 2.4.1"},
      # zen_ex prevents {:poison, "~> 4.0.1"},
      {:poison, "~> 3.1.0"},
      {:postgrex, ">= 0.0.0"},
      {:scrivener_ecto, "~> 2.7.0"},
      {:shorter_maps, "~> 2.0"},
      {:sweet_xml, ">=0.0.0"},
      {:test_parrot, "0.3.0"},
      {:timex, "~> 3.7.1"},
      {:uuid, "~> 1.1"},
      {:xlsxir, "~> 1.6.4"},
      {:xml_builder, "~> 2.1.1"},
      {:triplex, "~> 1.3.0"},
      {:slugify, "~> 1.3"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: [
        "ecto.create --quiet",
        "ecto.migrate",
        "multi_tenant_setup",
        "triplex.migrate",
        "test"
      ],
      "test.integration": [
        "ecto.create --quiet",
        "ecto.migrate",
        "multi_tenant_setup",
        "triplex.migrate",
        &put_integration_env/1,
        "test"
      ],
      "test.with_external": ["test --include external_api:true"],
      "test.all": [
        "test --include external_api:true --include flaky:true --include pdfs:true"
      ],
      "test.failfast": ["test --max-failures 3"],
      "test.external": ["test --include external_api test/full_system/"],
      "test.no_slow": ["test --exclude slow"],
      "test.show_slow": ["test --slowest 30 --exclude slow"],
      "test.accept": ["test test/acceptance --include acceptance_test"],
      "coveralls.integration": [&put_integration_env/1, "coveralls"],
      "coveralls.integration.html": [&put_integration_env/1, "coveralls.html"]
    ]
  end

  defp test_paths(:integration), do: ["test/integration"]
  defp test_paths(_), do: ["test/unit"]

  def put_integration_env(_args), do: System.put_env("MIX_ENV", "integration")
end
