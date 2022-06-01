# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

config :phoenix, :json_library, Jason

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

# General application configuration
config :app_count,
  ecto_repos: [AppCount.Repo]

config :triplex,
  repo: AppCount.Repo,
  unsafe_db_warning: false,
  reserved_schemas: ["public"]

# Configures the endpoint
config :app_count,
       AppCountWeb.Endpoint,
       check_origin: false,
       pubsub_server: AppCount.PubSub,
       secret_key_base: "K9G3FMB3CyIN4L4WwincIIEThyPuY/IfU1WUQ08RF9cFEyUleItownCTxQMWvrDJ",
       live_view: [signing_salt: "yfSfnyE+jJ+NUJgIWL/AznyuXifXKAro"],
       url: [host: "localhost"],
       render_errors: [
         view: AppCountWeb.ErrorView,
         accepts: ~w(html json)
       ]

# HoneyBadger configuration -- this bit is global to the application. We set
# env-specific key/value pairs in the env-specific config files.
#
# To see all config values: https://github.com/honeybadger-io/honeybadger-elixir
config :honeybadger,
  api_key: "2e30e799",
  exclude_envs: [:dev, :test, :staging]

config :logger,
  # extra logging
  # handle_otp_reports: true,
  # handle_sasl_reports: true,
  backends: [
    {LoggerFileBackend, :info},
    {LoggerFileBackend, :error},
    {LoggerFileBackend, :debug},
    {LoggerFileBackend, :warn},
    {LoggerFileBackend, :unsafe_db_call}
  ]

config :logger,
       :debug,
       path: "./log/debug.log",
       level: :debug,
       format: "\n$date $time $metadata[$level] $levelpad$message\n"

config :logger,
       :info,
       path: "./log/info.log",
       level: :info,
       format: "\n$date $time $metadata[$level] $levelpad$message\n"

config :logger,
       :warn,
       path: "./log/warn.log",
       level: :warn,
       format: "\n$date $time $metadata[$level] $levelpad$message\n"

config :logger,
       :error,
       path: "./log/error.log",
       level: :error,
       format: "\n$date $time $metadata[$level] $levelpad$message\n"

config :goth, json: "./config/gcp.secret.json" |> File.read!()

# my custom logger to log schema warnings
config :logger,
       :unsafe_db_call,
       path: "./log/unsafe_db_call.log",
       level: :warn,
       metadata_filter: [unsafe_db_call: true],
       format: "\n$date $time $metadata[$level] $levelpad$message\n"

# Configures Elixir's Logger
# config :logger,
#       :console,
#       format: "$time $metadata[$level] $message\n",
#       metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
