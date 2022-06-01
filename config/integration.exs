use Mix.Config

apprent_db_username = System.get_env("APPRENT_DB_USERNAME", System.get_env("USER", "postgres"))
apprent_db_password = System.get_env("APPRENT_DB_PASSWORD", "")

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :app_count,
       AppCountWeb.Endpoint,
       http: [
         port: 4001
       ],
       server: false

# Print only warnings and errors during test
config :logger, level: :info

config :honeybadger,
  environment_name: :dev

config :app_count, :utc_now_fn, fn ->
  # monday at noon
  ~U[2020-11-09 12:00:00Z]
end

# Use this stub to isolate tested behavior to a single process
config :app_count, :queue, AppCount.Support.SynchronousQueue
# Use this stub to process synchronously so that tests do not crash the DB sandbox
config :app_count, :http_client, AppCount.Support.HTTPClient

config :app_count, adapters: [tasker: AppCount.Support.InlineTask]

# Configure your database
config :app_count,
       AppCount.Repo,
       username: apprent_db_username,
       password: apprent_db_password,
       database: "app_count_test",
       hostname: "localhost",
       pool_size: 10,
       pool: Ecto.Adapters.SQL.Sandbox

#  ownership_timeout: 300_000,
#  timeout: 300_000

config :app_count, AppCountCom.Mailer.Test, adapter: Bamboo.TestAdapter

config :app_count, AppCount, %{
  environment: :test,
  authorize_env: :sandbox,
  task_queue_active: false,
  cache_genserver_states: false,
  apprent_crypt: %{
    secret: "wuivsaqr903423revuwf43q9r43iung2",
    sign: "affprent!"
  },
  forms_iv: "dev-environment!",
  rent_apply_key:
    Path.expand("./config/pub.key")
    |> File.read!()
    |> String.to_integer(),
  socket_path:
    (System.get_env("SOCKET_PATH") || Path.expand("server.sock"))
    |> URI.encode_www_form(),
  crypto_server_path: Path.expand("crypto/crypto"),
  local_crypto_key: "dmgMPNnFavFkpv4J2OxhL46yYCDzdOU8kzQrCEXXaDg=",
  home_url: "http://localhost:4001",
  tz: :timecop
}

# only needed by external_test
config :app_count, AppCount.Adapters.Twilio.Credential,
  sid: "ACb00a5b065ca8143b493adc85b6ac272b",
  token: "5e026d4b7abf61162fe1a837e6d9d9bc",
  phone_from: "+15005550006",
  url: "https://api.twilio.com/2010-04-01/Accounts/#{System.get_env("TWILIO_SID")}/Messages.json"

config :app_count, AppCount.Adapters.SoftLedger.Credential,
  grant_type: "client_credentials",
  audience: "https://sl-sb.softledger.com",
  client_id: "kblnl4ynjhzeEX5OlTgKUZ5UQbvG1m9Q",
  client_secret: "BtH7ROLm0HHr7F-U2HMiPxkY5-HHmQga-WESKBritpbzSC8Uw5J1shU4LrUlZzix",
  tenantUUID: "01978f23-a529-4cdd-938e-219ea9e720b7"

config :app_count, AppCount.Adapters.SoftLedger.Config,
  url: "https://sb-api.softledger.com/api",
  # sandbox underscore_id for root location is 876
  parent_id: 876,
  # sandbox number for ar_account is 532_820
  # sandbox underscore_id for ar_account 10_855
  ar_account_id: 10_855

config :app_count, AppCount.Core.FeatureFlags, using_soft_ledger: true

config :app_count, TenantSafe, %{
  user_id: "user_id",
  password: "Password!",
  postback: "https://administration.example.xom/tenant_safe"
}

# Use fake HTTPClient for all AWS requests
config :ex_aws,
  http_client: AppCount.Support.HTTPClient,
  access_key_id: ["ABCDEFGHIJKLMNOP", :instance_role],
  secret_access_key: ["ABCDEFGHIJKLMNOP", :instance_role],
  region: "us-east-2"
