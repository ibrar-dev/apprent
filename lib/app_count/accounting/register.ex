defmodule AppCount.Accounting.Register do
  use Ecto.Schema
  import Ecto.Changeset

  schema "accounting__registers" do
    field :is_default, :boolean
    field :type, :string
    belongs_to :property, Module.concat(["AppCount.Properties.Property"])
    belongs_to :account, Module.concat(["AppCount.Accounting.Account"])

    timestamps()
  end

  @doc false
  def changeset(register, attrs) do
    register
    |> cast(attrs, [:is_default, :property_id, :account_id, :type])
    |> validate_required([:property_id, :account_id])
    |> unique_constraint(:one_default_per_type,
      name: :accounting__registers_property_id_type_index
    )
  end
end
