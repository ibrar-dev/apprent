defmodule AppCountWeb.UploadChannel do
  use AppCountWeb, :channel
  alias AppCount.Data.Upload
  alias AppCount.Data.UploadURL
  alias AppCount.Repo
  import Ecto.Query

  def join(_topic, _alert, socket) do
    {:ok, %{id: socket.assigns.admin.id}, socket}
  end

  def alert_upload_event(upload_uuid, event) do
    {url, path} =
      from(
        u in Upload,
        join: url in UploadURL,
        on: url.id == u.id,
        where: u.uuid == ^upload_uuid,
        select: {url.url, fragment("? || '/' || ?", u.uuid, u.filename)}
      )
      |> Repo.one()

    AppCountWeb.Endpoint.broadcast("uploads", event, %{path: path, url: url})
  end
end
