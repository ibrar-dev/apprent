defmodule AppCount.UploadServer do
  use GenServer
  alias AppCount.UploadServer.Upload
  @process_name :uploads_server
  @abort_time 60_000 * 5

  @spec initialize_upload(integer, String.t(), String.t()) :: String.t()
  def initialize_upload(num_pieces, filename, type) do
    uuid = GenServer.call(@process_name, {:initialize, num_pieces, filename, type})
    Process.send_after(@process_name, {:abort, uuid}, @abort_time)
    uuid
  end

  @spec push_piece(%Plug.Upload{}) :: :ok | :error
  def push_piece(%Plug.Upload{} = upload) do
    GenServer.call(@process_name, upload)
  end

  @spec push_piece(String.t(), binary, integer) :: :ok | :error
  def push_piece(uuid, data, num) do
    GenServer.call(@process_name, {:piece, uuid, data, num})
  end

  @spec finish(String.t()) :: %Upload{}
  def finish(uuid) do
    GenServer.call(@process_name, {:finish, uuid})
  end

  # Callbacks

  def start_link(_opts \\ []) do
    AppCount.GenserverLogger.starting(__MODULE__)
    GenServer.start_link(__MODULE__, [], name: @process_name)
  end

  def init(_) do
    {:ok, %{}}
  end

  def handle_call({:initialize, num, filename, type}, _, state) do
    upload = Upload.new(num, filename, type)
    {:reply, upload.uuid, Map.put(state, upload.uuid, upload)}
  end

  def handle_call({:finish, uuid}, _, state) do
    upload = state[uuid]

    reply =
      if upload do
        validate(upload)
      else
        {:error, "Invalid Session ID"}
      end

    {:reply, reply, Map.delete(state, uuid)}
  end

  def handle_call(:pending, _, state), do: {:reply, state, state}

  def handle_call({:piece, uuid, data, num}, _, state) do
    do_push_piece(uuid, data, num, state)
  end

  def handle_call(%Plug.Upload{filename: f, path: p}, _, state) do
    try do
      [uuid, number, _] = String.split(f, ".")
      num = String.to_integer(number)
      do_push_piece(uuid, File.read!(p), num, state)
    rescue
      _ -> {:reply, :error, state}
    end
  end

  def handle_info({:abort, uuid}, state), do: {:noreply, Map.delete(state, uuid)}

  defp do_push_piece(uuid, data, num, state) do
    try do
      {:reply, :ok, update_in(state[uuid], &Upload.push_piece(&1, data, num))}
    rescue
      _ -> {:reply, :error, state}
    end
  end

  # if no content type was provided, attempt to determine it from the binary itself
  defp validate(%Upload{content_type: c, chunks: [first | _]} = upload)
       when c == "" or is_nil(c) do
    type = AppCount.Data.file_type(first)

    Map.merge(upload, %{
      content_type: MIME.type("#{type}"),
      filename: "#{upload.filename}.#{type}"
    })
  end

  defp validate(upload), do: upload
end
