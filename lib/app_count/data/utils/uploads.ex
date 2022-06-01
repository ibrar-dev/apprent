defmodule AppCount.Data.Utils.Uploads do
  alias AppCount.Repo
  alias AppCount.UploadServer
  alias AppCount.Data.Upload
  require Logger
  @bucket "appcount-uploads"

  def create_upload(params) do
    %Upload{}
    |> Upload.changeset(params)
    |> Repo.insert()
  end

  def upload_channel do
    # FIX_DEPS It would be best to send the event without dependancy on AppCountWeb.
    Module.concat(["AppCountWeb.UploadChannel"])
  end

  def initialize_upload(num_pieces, filename, type) do
    UploadServer.initialize_upload(num_pieces, filename, type)
  end

  @spec process_upload(term, list) :: {:error, String.t()} | {:ok, map()}
  def process_upload(%UploadServer.Upload{} = upload, opts) do
    AppCount.Core.Tasker.start(fn -> do_upload(upload, opts) end)
    convert(upload, opts)
  end

  def process_upload(uuid, opts) when is_binary(uuid),
    do: process_upload(UploadServer.finish(uuid), opts)

  def process_upload(e, _), do: e

  def convert(%UploadServer.Upload{} = upload, opts) do
    %{
      size: Enum.reduce(upload.chunks, 0, &(&2 + byte_size(&1))),
      uuid: upload.uuid,
      content_type: upload.content_type,
      filename: upload.filename,
      is_public: opts[:public]
    }
  end

  def do_upload(%UploadServer.Upload{} = upload, opts \\ []) do
    options =
      if opts[:public] do
        [acl: :public_read]
      else
        []
      end
      |> Keyword.merge(content_type: upload.content_type, timeout: 90_000, max_concurrency: 1)

    path = "#{upload.uuid}/#{upload.filename}"

    try do
      upload.chunks
      |> ExAws.S3.upload(@bucket, path, options)
      |> do_push
      |> case do
        {:ok, _} ->
          params = convert(upload, opts)

          Repo.get_by(Upload, uuid: upload.uuid)
          |> case do
            nil ->
              %Upload{}
              |> Upload.changeset(Map.merge(params, %{is_loading: false}))
              |> Repo.insert()

            gotten ->
              Upload.changeset(gotten, %{is_loading: false})
              |> Repo.update()
          end

          #          |> Upload.changeset(%{is_loading: false})
          #          |> Repo.update()

          upload_channel().alert_upload_event(upload.uuid, "FINISHED")

        {:error, e} ->
          Logger.error(inspect(e))
          mark_error(upload)
      end
    rescue
      _ -> mark_error(upload)
    catch
      :exit, _ -> mark_error(upload)
    end
  end

  def mark_error(upload) do
    Upload
    |> Repo.get_by(uuid: upload.uuid)
    |> Upload.changeset(%{is_error: true, is_loading: false})
    |> Repo.update()

    upload_channel().alert_upload_event(upload.uuid, "FINISHED")
  end

  @spec binary_to_upload(binary, String.t(), String.t()) :: String.t()
  def binary_to_upload(binary, filename, file_type) do
    chunks = chunkify(binary, [])
    uuid = UploadServer.initialize_upload(length(chunks), filename, file_type)

    chunks
    |> Enum.with_index(1)
    |> Enum.each(fn {data, num} -> UploadServer.push_piece(uuid, data, num) end)

    uuid
  end

  defp chunkify(data, chunks) do
    {chunk, rest} = String.split_at(data, 1024 * 1024)

    if rest == "" do
      chunks ++ [chunk]
    else
      chunkify(rest, chunks ++ [chunk])
    end
  end

  if Mix.env() == :test do
    def do_push(_request), do: {:ok, nil}
  else
    def do_push(request), do: ExAws.request(request, host: "s3-us-east-2.amazonaws.com")
  end
end
