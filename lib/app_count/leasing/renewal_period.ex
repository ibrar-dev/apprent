defmodule AppCount.Leasing.RenewalPeriod do
  use Ecto.Schema
  import Ecto.Changeset

  schema "leasing__renewal_periods" do
    field :creator, :string
    field :approval_date, :date
    field :approval_admin, :string
    field :start_date, :date
    field :end_date, :date
    field :approval_request, :naive_datetime
    field :notes, {:array, :map}
    belongs_to :property, Module.concat(["AppCount.Properties.Property"])
    has_many :packages, Module.concat(["AppCount.Leasing.RenewalPackage"])

    #    has_many :custom_packages, Module.

    timestamps()
  end

  @doc false
  def changeset(renewal_period, attrs) do
    renewal_period
    |> cast(attrs, [
      :creator,
      :approval_date,
      :approval_admin,
      :start_date,
      :end_date,
      :property_id,
      :notes,
      :approval_request
    ])
    |> validate_required([:creator, :property_id, :start_date, :end_date])
    |> exclusion_constraint(:period_overlap,
      name: :period_duration_overlap,
      message: "Period conflicts with another period"
    )
  end
end
