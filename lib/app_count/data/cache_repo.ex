defmodule AppCount.Data.CacheRepo do
  alias AppCount.Repo
  alias AppCount.Data.Cache

  def set(key, content) do
    %Cache{}
    |> Cache.changeset(%{key: key, content: pack(content)})
    |> Repo.insert(on_conflict: {:replace_all_except, [:id, :key]}, conflict_target: :key)
  end

  def get(key) when is_binary(key) do
    Repo.get_by(Cache, key: key)
    |> unpack
  end

  def clear(key) when is_binary(key) do
    Repo.get_by(Cache, key: key)
    |> Repo.delete()
  end

  defp pack(content) do
    content
    |> :erlang.term_to_binary()
    |> Base.encode64()
  end

  defp unpack(nil), do: nil

  defp unpack(%{content: packed_content}) do
    packed_content
    |> Base.decode64!()
    |> :erlang.binary_to_term()
  end
end
