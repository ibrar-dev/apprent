defmodule AppCount.Data.Utils.Migrator do
  alias AppCount.Repo
  alias AppCount.Data
  import Ecto.Query
  require Logger

  def migrate_attachment(module, old_field, new_field) do
    new_field_key = :"#{new_field}_id"

    from(i in module,
      where: not is_nil(field(i, ^old_field)),
      where: is_nil(field(i, ^new_field_key))
    )
    |> Repo.all()
    |> Enum.each(fn item -> migrate_item(item, module, old_field, new_field) end)
  end

  def migrate_item(item, module, old_field, new_field) do
    Logger.info("Migrating #{item.id}...")

    item
    |> Map.get(old_field)
    |> HTTPoison.get()
    |> case do
      {:ok, %HTTPoison.Response{status_code: 200} = r} ->
        Logger.info("got file data")
        uuid = create_upload(r)
        Logger.info("created upload")

        item
        |> module.changeset(%{
          new_field => %{
            "uuid" => uuid
          }
        })
        |> Repo.update()

        Logger.info("success")

      e ->
        e
    end
  end

  def create_upload(%{body: data, headers: headers, request_url: request_url}) do
    {_, type} = Enum.find(headers, fn {h, _} -> h == "Content-Type" end)

    filename =
      URI.parse(request_url).path
      |> String.replace(~r/.*\//, "")
      |> URI.decode()

    Data.binary_to_upload(data, filename, type)
  end
end
