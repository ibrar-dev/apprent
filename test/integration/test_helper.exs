{:ok, _} = Application.ensure_all_started(:ex_machina)
{:ok, _} = Application.ensure_all_started(:app_count)

include_pdfs_testing = System.get_env("APPRENT_GS_INSTALLED", "true")
exclude_pdfs_testing = include_pdfs_testing != "true"

ExUnit.start()

# Tests that his external APIs are excluded by default. You can include them
# like so:
#
# mix test --include external_api
#    or
# mix test.with_external
#
# PDF tests are included by default, but can be included/excluded in the same
# way

ExUnit.configure(
  exclude: [
    flaky: true,
    # slow: true,
    pdfs: exclude_pdfs_testing,
    external_api: true,
    acceptance_test: true
  ]
)

# :ok = Ecto.Adapters.SQL.Sandbox.checkout(AppCount.Repo)

# Ecto.Adapters.SQL.Sandbox.mode(AppCount.Repo, {:shared, self()})

Agent.start(fn -> nil end, name: :timecop)
