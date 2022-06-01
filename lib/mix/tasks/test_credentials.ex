defmodule Mix.Tasks.TestCredentials do
  use Mix.Task
  alias AppCount.Repo
  alias AppCount.Properties

  @name_key %{
    ba: "Payscape",
    cc: "Authorize",
    lease: "BlueMoon",
    screening: "TenantSafe",
    management: "Yardi"
  }

  @shortdoc "Sets up test credentials"
  @spec run(any) :: no_return()
  def run(_) do
    Enum.each([:logger, :ssl, :postgrex, :ecto, :httpoison], &Application.ensure_all_started/1)
    AppCount.Crypto.start_crypto_server()
    Repo.start_link(log: false)
    credentials = Application.get_env(:app_count, :processors)

    Repo.all(Properties.Property)
    |> Enum.each(fn property ->
      Map.keys(credentials)
      |> Enum.each(fn credential ->
        case Repo.get_by(Properties.Processor, property_id: property.id, type: "#{credential}") do
          nil ->
            Properties.create_processor(%{
              property_id: property.id,
              type: "#{credential}",
              name: @name_key[credential],
              keys: credentials[credential]
            })

          processor ->
            Properties.update_processor(processor.id, %{keys: credentials[credential]})
        end
      end)
    end)
  end
end
