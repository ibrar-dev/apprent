defmodule AppCount.Accounting.Invoicing do
  use Ecto.Schema
  import Ecto.Changeset

  schema "accounting__invoicings" do
    field :amount, :decimal
    field :notes, :string
    belongs_to :invoice, Module.concat(["AppCount.Accounting.Invoice"])
    belongs_to :property, Module.concat(["AppCount.Properties.Property"])
    belongs_to :account, Module.concat(["AppCount.Accounting.Account"])
    has_many :payments, Module.concat(["AppCount.Accounting.InvoicePayment"])

    many_to_many :checks, Module.concat(["AppCount.Accounting.Check"]),
      join_through: Module.concat(["AppCount.Accounting.InvoicePayment"])

    timestamps()
  end

  @doc false
  def changeset(invoicing, attrs) do
    invoicing
    |> cast(attrs, [:invoice_id, :property_id, :account_id, :amount, :notes])
    |> validate_required([:invoice_id, :property_id, :account_id, :amount])
  end
end
