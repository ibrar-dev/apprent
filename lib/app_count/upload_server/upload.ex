defmodule AppCount.UploadServer.Upload do
  @chunk_size 5 * 1024 * 1024

  defstruct filename: nil,
            content_type: "",
            num_pieces: 0,
            processed: 0,
            pieces: %{},
            chunks: [],
            is_public: false,
            uuid: ""

  def new(num, filename, type) do
    pieces =
      List.duplicate("", num)
      |> Enum.with_index(1)
      |> Enum.into(%{}, fn {v, i} -> {i, v} end)

    %__MODULE__{
      num_pieces: num,
      pieces: pieces,
      filename: filename,
      content_type: type,
      uuid: UUID.uuid4()
    }
  end

  def push_piece(%__MODULE__{} = upload, data, num) do
    updated = Map.put(upload.pieces, num, data)

    {new_chunks, new_pieces, _, _, _} =
      updated
      |> Enum.reduce_while({upload.chunks, updated, "", 0, []}, &process_piece/2)

    upload
    |> Map.merge(%{chunks: new_chunks, pieces: new_pieces, processed: upload.processed + 1})
    |> finalize
  end

  defp finalize(%__MODULE__{num_pieces: n, processed: p} = upload) when n == p do
    last_chunk =
      upload.pieces
      |> Map.values()
      |> Enum.join()

    Map.merge(upload, %{chunks: upload.chunks ++ [last_chunk], pieces: %{}})
  end

  defp finalize(%__MODULE__{} = u), do: u

  defp process_piece({_, ""}, {chunks, pieces, a, b, c}) do
    {:halt, {chunks, pieces, a, b, c}}
  end

  defp process_piece({index, piece}, {chunks, pieces, current_chunk, chunk_length, indices}) do
    chunk_length = chunk_length + byte_size(piece)
    current_chunk = current_chunk <> piece

    if chunk_length >= @chunk_size do
      {new_chunk, rest} = String.split_at(current_chunk, @chunk_size)
      indices = if rest == "", do: indices ++ [index], else: indices

      pieces =
        if rest == "" do
          Map.drop(pieces, indices ++ [index])
        else
          Map.drop(pieces, indices)
          |> Map.put(index, rest)
        end

      {:cont, {chunks ++ [new_chunk], pieces, rest, chunk_length - @chunk_size, []}}
    else
      {:cont, {chunks, pieces, current_chunk, chunk_length, indices ++ [index]}}
    end
  end
end
