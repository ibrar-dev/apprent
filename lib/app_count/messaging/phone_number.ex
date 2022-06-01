defmodule AppCount.Messaging.PhoneNumber do
  @moduledoc """
  Where we store the phone numbers that AppRent uses to text things.
  These are unique to each property.
  The context param is to be used if we want specific phone numbers for spceific modules.
  For example, if we want all Payment related texts to be sent and recieved from one number and Maintenance from a different one.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @required_fields [
    :number,
    :context,
    :property_id
  ]

  @derive {Jason.Encoder, only: @required_fields ++ [:id, :inserted_at]}

  schema "messaging__phone_numbers" do
    field :number, :string
    field :context, :string, default: "all"
    belongs_to :property, AppCount.Properties.Property

    timestamps()
  end

  @doc false
  def changeset(phone_number, attrs) do
    phone_number
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(
      :number,
      name: :messaging__phone_numbers_number_index,
      message: "number already in use"
    )
  end
end
