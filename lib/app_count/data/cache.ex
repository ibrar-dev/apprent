defmodule AppCount.Data.Cache do
  use Ecto.Schema
  import Ecto.Changeset

  schema "data__caches" do
    field :content, :string
    field :key, :string

    timestamps()
  end

  @doc false
  def changeset(cache, attrs) do
    cache
    |> cast(attrs, [:key, :content])
    |> validate_required([:key, :content])
  end
end
