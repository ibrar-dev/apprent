defmodule AppCount.RentApply.RentApplication do
  use Ecto.Schema
  import Ecto.Changeset
  alias AppCount.RentApply.RentApplication
  alias AppCount.RentApply.Vehicle
  alias AppCount.RentApply.Employment
  alias AppCount.RentApply.History
  alias AppCount.RentApply.Document
  alias AppCount.RentApply.MoveIn
  alias AppCount.RentApply.Income
  alias AppCount.Leases.Form
  alias AppCount.Tenants.Tenant
  alias AppCount.Ledgers.Payment
  alias AppCount.RentApply.Memo
  alias AppCount.Admins.Device
  alias AppCount.Prospects.Prospect

  @derive {Poison.Encoder,
           only: [
             :emergency_contacts,
             :employments,
             :histories,
             :lang,
             :move_in,
             :occupants,
             :persons,
             :pets,
             :start_time,
             :vehicles
           ]}

  schema "rent_apply__rent_applications" do
    field(:bluemoon_lease_id, :string)
    field(:declined_by, :string)
    field(:declined_on, :date)
    field(:declined_reason, :string)
    field(:is_conditional, :boolean)
    field(:lang, :string)
    field(:referral, :string)
    # maybe seconds since epoch
    field(:start_time, :integer)
    field(:status, :string, default: "submitted")
    field(:terms_and_conditions, :string, default: "")

    embeds_one(:approval_params, AppCount.RentApply.ApprovalParams, on_replace: :update)

    belongs_to(:device, Device)
    belongs_to(:property, AppCount.Properties.Property)
    belongs_to(:prospect, Prospect)
    belongs_to(:saved_form, AppCount.RentApply.Forms.SavedForm)
    belongs_to(:customer_ledger, AppCount.Ledgers.CustomerLedger)

    has_many(:documents, Document, foreign_key: :application_id)
    has_many(:employments, Employment, foreign_key: :application_id)
    has_many(:histories, History, foreign_key: :application_id)
    has_many(:memos, Memo, foreign_key: :application_id)
    has_many(:payments, Payment, foreign_key: :application_id)
    has_many(:persons, AppCount.RentApply.Person, foreign_key: :application_id)
    has_many(:pets, AppCount.RentApply.Pet, foreign_key: :application_id)
    has_many(:vehicles, Vehicle, foreign_key: :application_id)

    has_many(
      :emergency_contacts,
      AppCount.RentApply.EmergencyContact,
      foreign_key: :application_id
    )

    has_one(:form, Form, foreign_key: :application_id)
    has_one(:income, Income, foreign_key: :application_id)
    has_one(:move_in, MoveIn, foreign_key: :application_id)
    has_one(:tenant, Tenant, foreign_key: :application_id)

    timestamps()
  end

  @doc false
  def changeset(%RentApplication{} = rent_application, attrs) do
    rent_application
    |> cast(
      attrs,
      [
        :bluemoon_lease_id,
        :declined_by,
        :declined_on,
        :declined_reason,
        :device_id,
        :is_conditional,
        :property_id,
        :prospect_id,
        :referral,
        :saved_form_id,
        :customer_ledger_id,
        # status: submitted, conditional, signed, declined, approved, preapproved
        :status,
        :terms_and_conditions
      ]
    )
    |> cast_approval_params(attrs)
    |> validate_required([:property_id, :status])
  end

  defp cast_approval_params(cs, %{approval_params: _}), do: cast_embed(cs, :approval_params)
  defp cast_approval_params(cs, %{"approval_params" => _}), do: cast_embed(cs, :approval_params)
  defp cast_approval_params(cs, _), do: cs

  def lease_holdering_person(%RentApplication{persons: persons}) do
    persons
    |> Enum.find(fn %AppCount.RentApply.Person{status: status} ->
      status == "Lease Holder"
    end)
  end
end
