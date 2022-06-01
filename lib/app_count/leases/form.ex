defmodule AppCount.Leases.Form do
  use Ecto.Schema
  import Ecto.Changeset
  use AppCount.EctoTypes.Attachment

  schema "leases__forms" do
    field :lease_date, :date
    field :bug_infestation, :integer
    field :bug_inspection, :integer
    field :bug_disclosure, :string
    field :buy_out_fee, :decimal
    field :code_change_fee, :boolean, default: false
    field :concession_fee, :decimal
    field :deposit_type, :string
    field :deposit_value, :string
    field :fitness_card_numbers, {:array, :string}
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
    field :concession_months, {:array, AppCount.EctoTypes.Month}
    field :other_discount, :string
    field :washer_rent, :decimal
    field :washer_type, :string
    field :washer_serial, :string
    field :dryer_serial, :string
    field :smart_fee, :decimal
    field :waste_cost, :decimal
    field :locked, :boolean
    field :form_id, :string
    field :signature_id, :string
    field :status, :map
    field :signed, :boolean
    field :admin, :string
    belongs_to :application, Module.concat(["AppCount.RentApply.RentApplication"])
    belongs_to :lease, Module.concat(["AppCount.Leases.Lease"])
    attachment(:document)

    timestamps()
  end

  @doc false
  def changeset(lease, attrs) do
    lease
    |> cast(
      attrs,
      [
        :application_id,
        :lease_date,
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
        :locked,
        :form_id,
        :lease_id,
        :status,
        :signature_id,
        :signed,
        :admin
      ]
    )
    |> cast_attachment(:document)
    |> check_constraint(:lease_id, name: :must_have_assoc)
    |> unique_constraint(:lease_id)
    |> unique_constraint(:application_id)
  end
end
