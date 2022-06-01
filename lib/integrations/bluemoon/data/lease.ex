defmodule BlueMoon.Data.Lease do
  use Ecto.Schema
  import Ecto.Changeset

  defmodule Signator do
    use Ecto.Schema
    import Ecto.Changeset

    embedded_schema do
      field :name, :string
      field :email, :string
      field :phone, :string
    end

    @doc false
    def changeset(m, attrs) do
      m
      |> cast(attrs, [:name, :email, :phone])
    end
  end

  defmodule Admin do
    use Ecto.Schema
    import Ecto.Changeset

    embedded_schema do
      field :name, :string
      field :email, :string
    end

    @doc false
    def changeset(m, attrs) do
      m
      |> cast(attrs, [:name, :email])
    end
  end

  embedded_schema do
    field :start_date, :date
    field :end_date, :date
    field :lease_date, :date
    field :bug_infestation, :integer
    field :bug_inspection, :integer
    field :bug_disclosure, :string
    field :buy_out_fee, :decimal
    field :concession_fee, :decimal
    field :prorated_rent, :decimal
    field :rent, :decimal
    field :deposit_type, :string
    field :deposit_value, :string
    field :insurance_company, :string
    field :code_change_fee, :boolean, default: false
    field :gate_access_card, :boolean, default: false
    field :gate_access_code, :boolean, default: false
    field :gate_access_remote, :boolean, default: false
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
    field :fitness_card_numbers, {:array, :string}, default: []
    field :residents, {:array, :string}, default: []
    field :occupants, {:array, :string}, default: []
    field :unit, :string
    embeds_many :signators, Signator
    embeds_one :admin, Admin
    field :ref, :string
  end

  @doc false
  def cast_params(attrs) do
    %__MODULE__{}
    |> cast(
      attrs,
      [
        :start_date,
        :end_date,
        :lease_date,
        :rent,
        :prorated_rent,
        :bug_infestation,
        :bug_inspection,
        :bug_disclosure,
        :buy_out_fee,
        :code_change_fee,
        :concession_fee,
        :deposit_type,
        :deposit_value,
        :fitness_card_numbers,
        :gate_access_card,
        :gate_access_code,
        :gate_access_remote,
        :insurance_company,
        :lost_card_fee,
        :lost_remote_fee,
        :mail_keys,
        :other_keys,
        :unit_keys,
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
        :residents,
        :occupants,
        :unit,
        :ref
      ]
    )
    |> cast_embed(:signators)
    |> cast_embed(:admin)
    |> apply_changes
  end
end
