defmodule AppCount.Properties.PhoneLine do
  use Ecto.Schema
  import Ecto.Changeset

  schema "properties__phone__lines" do
    field :number, :string
    belongs_to :property, Module.concat(["AppCount.Properties.Property"])

    timestamps()
  end

  @doc false
  def changeset(phone_line, attrs) do
    phone_line
    |> cast(attrs, [:number, :property_id])
    |> validate_required([:number, :property_id])
    |> unique_constraint(:number)
    |> check_constraint(:number, name: :valid_phone_number)
  end
end
