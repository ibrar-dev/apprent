defmodule AppCount.Accounting.Check do
  use Ecto.Schema
  import Ecto.Changeset
  use AppCount.EctoTypes.Attachment

  schema "accounting__checks" do
    field :date, :date
    field :number, :integer
    field :cleared, :boolean
    field :printed, :boolean
    field :amount, :decimal
    field :amount_lang, :string
    belongs_to :bank_account, AppCount.Accounting.BankAccount
    belongs_to :payee, AppCount.Accounting.Payee
    belongs_to :tenant, AppCount.Tenants.Tenant
    belongs_to :charge, AppCount.Ledgers.Charge
    belongs_to :lease, AppCount.Leases.Lease
    belongs_to :applicant, AppCount.RentApply.Person
    has_many :payments, AppCount.Accounting.InvoicePayment

    many_to_many :invoicings,
                 AppCount.Accounting.Invoicing,
                 join_through: AppCount.Accounting.InvoicePayment

    attachment(:document)

    timestamps()
  end

  @doc false
  def changeset(check, attrs) do
    check
    |> cast(
      attrs,
      [
        :amount_lang,
        :number,
        :date,
        :bank_account_id,
        :payee_id,
        :tenant_id,
        :cleared,
        :printed,
        :charge_id,
        :lease_id,
        :applicant_id,
        :amount
      ]
    )
    |> cast_attachment(:document)
    |> validate_required([:number, :date, :bank_account_id, :amount])
    |> unique_constraint(
      :number,
      name: :accounting_checks_number_bank_account_id_index,
      message: "Cannot create a check number that already exists."
    )
    |> check_constraint(:payee, name: :has_one_payee)
    |> check_constraint(:charge, name: :tenant_checks_have_charge)
    |> check_constraint(:inv_charge, name: :invoice_checks_have_no_charge)
  end
end
