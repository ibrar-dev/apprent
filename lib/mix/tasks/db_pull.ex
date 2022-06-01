defmodule Mix.Tasks.DbPull do
  use Mix.Task
  @apprent_db_user System.get_env("APPRENT_DB_USERNAME", System.get_env("USER", "postgres"))

  @shortdoc ""
  @spec run(any) :: no_return()
  def run(_) do
    HTTPoison.start()
    IO.puts("Pulling production database...")
    AppCount.Utils.db_dump()
    IO.puts("Done.")
    IO.puts("Dropping dev database...")
    Mix.Tasks.Ecto.Drop.run([])
    IO.puts("Done.")
    IO.puts("Creating new dev database...")
    Mix.Tasks.Ecto.Create.run([])
    IO.puts("Done.")
    IO.puts("Importing production data...")

    System.cmd(
      "pg_restore",
      [
        "--no-privileges",
        "--no-owner",
        "-d",
        "app_count_dev",
        "-U",
        @apprent_db_user,
        "-Fc",
        "/tmp/appcount-db/db.dump"
      ]
    )

    IO.puts("Done.")
    IO.puts("Setting test credentials...")
    Mix.Tasks.TestCredentials.run([])
    IO.puts("Done.")
    IO.puts("Import complete.")
  end
end
