defmodule AppCount.Units.DefaultLeaseCharge do
  use Ecto.Schema
  import Ecto.Changeset

  schema "units__default_lease_charges" do
    field :price, :integer
    field :history, {:array, :map}
    field :default_charge, :boolean, default: true
    belongs_to :floor_plan, Module.concat(["AppCount.Properties.FloorPlan"])
    belongs_to :charge_code, Module.concat(["AppCount.Ledgers.ChargeCode"])

    timestamps()
  end

  @doc false
  def changeset(default_lease_charges, attrs) do
    default_lease_charges
    |> cast(attrs, [:price, :history, :default_charge, :floor_plan_id, :charge_code_id])
    |> validate_required([:price, :floor_plan_id, :default_charge, :charge_code_id])
  end
end
