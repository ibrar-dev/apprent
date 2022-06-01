defmodule AppCount.Properties.Insurance do
  use Ecto.Schema
  import Ecto.Changeset

  schema "properties__insurances" do
    field :amount, :decimal
    field :begins, :date
    field :canceled, :date
    field :company, :string
    field :ends, :date
    field :number, :string
    field :reinstate, :date
    field :title, :string
    field :interested_party, :boolean, default: false
    field :legal_liability, :boolean, default: false
    field :pet_endorsement, :boolean, default: false
    field :renewal, :boolean, default: false
    field :satisfies_move_in, :boolean, default: false
    belongs_to :tenant, Module.concat(["AppCount.Tenants.Tenant"])

    timestamps()
  end

  @doc false
  def changeset(insurance, attrs) do
    insurance
    |> cast(
      attrs,
      [
        :tenant_id,
        :company,
        :begins,
        :ends,
        :title,
        :amount,
        :canceled,
        :number,
        :reinstate,
        :renewal,
        :legal_liability,
        :satisfies_move_in,
        :interested_party,
        :pet_endorsement
      ]
    )
    |> validate_required([:tenant_id, :company, :begins, :ends, :amount, :number])
  end
end
