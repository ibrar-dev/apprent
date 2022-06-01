defmodule AppCount.Exports.Utils.Documents do
  alias AppCount.Repo
  alias AppCount.Exports.Document
  alias AppCount.Exports.Recipient
  import Ecto.Query

  def insert_document(params) do
    %Document{}
    |> Document.changeset(params)
    |> Repo.insert()
    |> maybe_send_to_recipients(params)
  end

  def update_document(id, params) do
    Repo.get(Document, id)
    |> Document.changeset(params)
    |> Repo.update()
  end

  def delete_document(id) do
    Repo.get(Document, id)
    |> Repo.delete()
  end

  def download(id) do
    url =
      from(
        d in Document,
        join: u in assoc(d, :document_url),
        where: d.id == ^id,
        select: u.url
      )
      |> Repo.one()

    data =
      url
      |> HTTPoison.get!()
      |> Map.get(:body)

    filename =
      url
      |> URI.parse()
      |> Map.get(:path)
      |> Path.basename()

    {filename, data}
  end

  def send_document(%Document{} = export, %{"binary" => binary, "message" => message} = params) do
    path = "/tmp/exports/#{UUID.uuid4()}"
    File.mkdir_p(path)
    full_path = "#{path}/tempfile"
    File.write!(full_path, binary)

    attachment = %Plug.Upload{
      content_type: export.type,
      filename: export.name,
      path: full_path
    }

    params["recipient_ids"]
    |> Enum.each(fn id ->
      rec = Repo.get(Recipient, id)

      AppCountCom.Messaging.send_individual_email(
        params["subject"],
        message,
        [attachment],
        rec.email
      )
    end)

    File.rm_rf!(path)
  end

  def send_document(%Document{} = export, %{"message" => _} = params) do
    case HTTPoison.get(export.document_url.url) do
      {:ok, %{body: body}} -> send_document(export, Map.put(params, "binary", body))
      _ -> {:error, "Cannot fetch document"}
    end
  end

  def send_document(id, params) do
    Repo.get(Document, id)
    |> Repo.preload(:document_url)
    |> send_document(params)
  end

  def maybe_send_to_recipients({:ok, export}, %{"recipient_ids" => _, "message" => _} = params) do
    AppCount.Core.Tasker.start(fn ->
      recipient_ids = String.split(params["recipient_ids"], ",")
      send_document(export, Map.put(params, "recipient_ids", recipient_ids))
    end)

    {:ok, export}
  end

  def maybe_send_to_recipients(r, _), do: r
end
