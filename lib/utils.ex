defmodule AppCount.Utils do
  # CONSOLE: AppCount.Utils.db_dump()
  def db_dump() do
    ExAws.S3.presigned_url(
      ExAws.Config.new(:s3),
      :get,
      "appcount-builds",
      "dumps/production/db.dump.zip"
    )
    |> case do
      {:ok, url} ->
        {:ok, %{body: body}} = HTTPoison.get(url, timeout: 12000, recv_timeout: 12000)
        File.mkdir_p("/tmp/appcount-db/")
        File.write("/tmp/appcount-db/db.dump.zip", body)
        :zip.unzip('/tmp/appcount-db/db.dump.zip', cwd: '/tmp/appcount-db/')

      {:error, e} ->
        {:error, e}
    end
  end

  def indifferent(%{} = hash, keys) when is_list(keys) do
    Enum.map(keys, &indifferent(hash, &1))
  end

  def indifferent(%{} = hash, key) when is_binary(key) do
    Map.get(hash, key, hash[String.to_atom(key)])
  end

  def indifferent(%{} = hash, key) when is_atom(key) do
    Map.get(hash, key, hash[Atom.to_string(key)])
  end

  def indifferent_has_key?(%{} = hash, key) when is_atom(key) do
    Map.has_key?(hash, key) || Map.has_key?(hash, "#{key}")
  end

  def indifferent_has_key?(%{} = hash, key) when is_binary(key) do
    Map.has_key?(hash, key) || Map.has_key?(hash, String.to_atom(key))
  end

  def matched_put(%{} = map, key, value) when is_atom(key) do
    map
    |> Map.keys()
    |> hd
    |> is_binary
    |> if do
      Map.put(map, "#{key}", value)
    else
      Map.put(map, key, value)
    end
  end

  def parse_csv(data) do
    [header_line | rest] = String.split(data, "\n")

    headers =
      String.split(header_line, ",")
      |> Enum.map(&String.trim/1)

    Enum.map(
      rest,
      fn line ->
        line
        |> String.split(",")
        |> Enum.with_index()
        |> Enum.into(
          %{},
          fn {item, index} ->
            {Enum.at(headers, index), item}
          end
        )
      end
    )
  end

  def put_public_s3(path, bin, opts \\ []) do
    options = Keyword.merge(opts, acl: :public_read)
    put_s3(path, bin, options)
  end

  def delimit(float) when is_float(float) do
    float
    |> Float.to_charlist()
    |> Enum.chunk_by(&(&1 == 46))
    |> List.update_at(0, &delimit/1)
    |> Enum.join()
  end

  def delimit(num) when is_integer(num) do
    num
    |> Integer.to_charlist()
    |> delimit
  end

  def delimit(charlist) do
    charlist
    |> :lists.reverse()
    |> Enum.chunk_every(3)
    |> Enum.join(",")
    |> String.reverse()
  end

  defp put_s3(full_path, bin, opts) do
    [bucket, path] = String.split(full_path, ":")

    ExAws.S3.put_object(bucket, path, bin, opts)
    |> ExAws.request(host: "s3-us-east-2.amazonaws.com")
  end
end
