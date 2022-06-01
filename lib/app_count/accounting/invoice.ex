defmodule AppCount.Accounting.Invoice do
  use Ecto.Schema
  import Ecto.Changeset
  use AppCount.EctoTypes.Attachment

  schema "accounting__invoices" do
    field :post_month, :date
    field :due_date, :date
    field :number, :string
    field :notes, :string
    field :date, :date
    field :amount, :decimal
    has_many :invoicings, Module.concat(["AppCount.Accounting.Invoicing"])
    belongs_to :payee, Module.concat(["AppCount.Accounting.Payee"])
    belongs_to :payable_account, Module.concat(["AppCount.Accounting.Account"])
    attachment(:document)

    many_to_many :properties,
                 Module.concat(["AppCount.Properties.Property"]),
                 join_through: Module.concat(["AppCount.Accounting.Invoicing"])

    timestamps()
  end

  @doc false
  def changeset(invoice, attrs) do
    invoice
    |> cast(attrs, [
      :post_month,
      :payee_id,
      :payable_account_id,
      :due_date,
      :number,
      :notes,
      :date,
      :amount
    ])
    |> cast_attachment(:document)
    |> validate_required([
      :post_month,
      :date,
      :payee_id,
      :payable_account_id,
      :due_date,
      :amount,
      :number
    ])
    |> unique_constraint(:number,
      name: :accounting__invoices_number_payee_id_index,
      message: "already taken for payee."
    )
    |> check_constraint(:post_month, name: :valid_post_month)
  end
end
