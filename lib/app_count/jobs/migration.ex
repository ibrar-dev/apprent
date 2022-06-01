defmodule AppCount.Jobs.Migration do
  use Ecto.Schema
  import Ecto.Changeset

  schema "jobs__migrations" do
    field :arguments, AppCount.Jobs.ArgList
    field :function, :string
    field :module, :string

    timestamps()
  end

  @doc false
  def changeset(migration, attrs) do
    migration
    |> cast(attrs, [:module, :function, :arguments])
    |> validate_required([:module, :function])
  end
end
