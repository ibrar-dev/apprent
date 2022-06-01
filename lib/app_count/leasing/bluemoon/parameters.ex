defmodule AppCount.Leasing.BlueMoon.Parameters do
  use Ecto.Schema
  import Ecto.Changeset

  defmodule Resident do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :name, :string
      field :email, :string
      field :phone, :string
    end

    def changeset(resident, attrs) do
      resident
      |> cast(attrs, [:name, :email, :phone])
      |> validate_required([:name, :email])
    end
  end

  @primary_key false
  embedded_schema do
    field :rent, :decimal
    field :start_date, :date
    field :end_date, :date
    field :lease_date, :date
    field :unit, :string
    field :bug_infestation, :integer
    field :bug_inspection, :integer
    field :bug_disclosure, :string
    field :buy_out_fee, :decimal
    field :code_change_fee, :boolean, default: false
    field :concession_fee, :decimal
    field :deposit_type, :string
    field :deposit_value, :string
    field :fitness_card_numbers, {:array, :string}, default: []
    field :gate_access_card, :boolean, default: false
    field :gate_access_code, :boolean, default: false
    field :gate_access_remote, :boolean, default: false
    field :insurance_company, :string
    field :lost_card_fee, :boolean, default: false
    field :lost_remote_fee, :boolean, default: false
    field :mail_keys, :integer
    field :other_keys, :integer
    field :unit_keys, :integer
    field :monthly_discount, :decimal
    field :one_time_concession, :decimal
    field :concession_months, {:array, AppCount.EctoTypes.Month}, default: []
    field :other_discount, :string
    field :washer_rent, :decimal
    field :washer_type, :string
    field :washer_serial, :string
    field :dryer_serial, :string
    field :smart_fee, :decimal
    field :waste_cost, :decimal
    embeds_many :residents, Resident
    field :occupants, {:array, :string}, default: []
  end

  def raw_parameters(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> apply_changes
    |> Map.from_struct()
    |> Map.update(:residents, [], fn resident_structs ->
      Enum.map(resident_structs, &Map.from_struct/1)
    end)
  end

  @doc false
  def changeset(lease, attrs) do
    lease
    |> cast(
      attrs,
      [
        :rent,
        :start_date,
        :end_date,
        :lease_date,
        :unit,
        :unit_keys,
        :mail_keys,
        :other_keys,
        :deposit_type,
        :deposit_value,
        :bug_infestation,
        :bug_inspection,
        :bug_disclosure,
        :buy_out_fee,
        :concession_fee,
        :fitness_card_numbers,
        :gate_access_remote,
        :gate_access_code,
        :gate_access_card,
        :lost_card_fee,
        :lost_remote_fee,
        :code_change_fee,
        :insurance_company,
        :monthly_discount,
        :one_time_concession,
        :concession_months,
        :other_discount,
        :washer_rent,
        :washer_type,
        :washer_serial,
        :dryer_serial,
        :smart_fee,
        :waste_cost,
        :occupants
      ]
    )
    |> cast_embed(:residents)
    |> validate_residents
    |> validate_required([:start_date, :end_date, :lease_date, :rent, :unit])
  end

  def validate_residents(changeset) do
    if apply_changes(changeset).residents == [] do
      add_error(changeset, :residents, "Must have at least 1 resident")
    else
      changeset
    end
  end
end
