defmodule AppCount.Data.Uploads do
  use Ecto.Type
  alias AppCount.Data.UploadURL.URL
  def type, do: :text
  def cast(x), do: {:ok, x}

  def load("{" <> paths) do
    urls =
      String.replace(paths, "}", "")
      |> String.split(",")
      |> Enum.map(fn path ->
        {:ok, url} = URL.load(path)
        url
      end)

    {:ok, urls}
  end

  def load(json) do
    Jason.decode!(json)
    |> to_url
  end

  def dump(x) do
    {:ok, x}
  end

  defp to_url(list) when is_list(list) do
    {:ok,
     Enum.map(list, fn %{"url" => url} = map ->
       {:ok, url} = URL.load(url)
       Map.put(map, "url", url)
     end)}
  end

  defp to_url(%{"url" => url} = map) do
    {:ok, url} = URL.load(url)
    {:ok, Map.put(map, "url", url)}
  end
end
