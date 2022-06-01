defmodule AppCount.Accounting.Entity do
  use Ecto.Schema
  import Ecto.Changeset

  schema "accounting__entities" do
    belongs_to :property, Module.concat(["AppCount.Properties.Property"])
    belongs_to :bank_account, Module.concat(["AppCount.Accounting.BankAccount"])

    timestamps()
  end

  @doc false
  def changeset(entity, attrs) do
    entity
    |> cast(attrs, [:property_id, :bank_account_id])
    |> validate_required([:property_id, :bank_account_id])
    |> unique_constraint(:unique, name: :accounting__entities_property_id_bank_account_id_index)
  end
end
