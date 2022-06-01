defmodule AppCount.Prospects.Memo do
  use Ecto.Schema
  import Ecto.Changeset

  schema "prospects__memos" do
    field :admin, :string
    field :notes, :string
    belongs_to :prospect, Module.concat(["AppCount.Prospects.Prospect"])

    timestamps()
  end

  @doc false
  def changeset(memos, attrs) do
    memos
    |> cast(attrs, [:admin, :notes, :prospect_id])
    |> validate_required([:admin, :notes, :prospect_id])
  end
end
