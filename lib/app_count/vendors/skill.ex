defmodule AppCount.Vendors.Skill do
  use Ecto.Schema
  import Ecto.Changeset
  alias AppCount.Vendors.Skill

  schema "vendors__skills" do
    belongs_to :category, Module.concat(["AppCount.Vendors.Category"])
    belongs_to :vendor, Module.concat(["AppCount.Vendors.Vendor"])

    timestamps()
  end

  @doc false
  def changeset(%Skill{} = skill, attrs) do
    skill
    |> cast(attrs, [:vendor_id, :category_id])
    |> validate_required([:vendor_id, :category_id])
    |> unique_constraint(:unique, name: :vendors__skills_vendor_id_category_id_index)
  end
end
