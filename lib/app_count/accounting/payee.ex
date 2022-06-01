defmodule AppCount.Accounting.Payee do
  use Ecto.Schema
  import Ecto.Changeset

  schema "accounting__payees" do
    field :name, :string
    field :street, :string
    field :city, :string
    field :state, :string
    field :zip, :string
    field :phone, :string
    field :email, :string
    field :tax_form, :string
    field :tax_id, :string
    field :due_period, :integer
    field :consolidate_checks, :boolean
    field :approved, :boolean, default: true
    has_many :invoices, AppCount.Accounting.Invoice

    timestamps()
  end

  @doc false
  def changeset(payee, attrs) do
    payee
    |> cast(attrs, [
      :name,
      :street,
      :city,
      :state,
      :zip,
      :email,
      :phone,
      :tax_form,
      :tax_id,
      :due_period,
      :consolidate_checks,
      :approved
    ])
    |> validate_required([:name])
  end
end
