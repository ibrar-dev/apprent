defmodule AppCount.Data.Upload do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder,
           only: [
             :content_type
           ]}

  schema "data__uploads" do
    field :content_type, :string
    field :filename, :string
    field :size, :integer
    field :is_public, :boolean
    field :is_loading, :boolean
    field :uuid, Ecto.UUID

    timestamps()
  end

  @doc false
  def changeset(upload, attrs) do
    upload
    |> cast(attrs, [:uuid, :filename, :size, :content_type, :is_public, :is_loading])
    |> validate_required([:uuid, :filename, :size, :content_type])
  end
end
