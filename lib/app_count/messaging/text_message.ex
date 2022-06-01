defmodule AppCount.Messaging.TextMessage do
  @moduledoc """
  For storing Text messages that have been sent and received.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @optional_fields [
    :media_types,
    :media_urls,
    :external_id,
    :status,
    :extra_params,
    :body
  ]

  @required_fields [
    :direction,
    :from_number,
    :to_number
  ]

  @derive {Jason.Encoder, only: @optional_fields ++ @required_fields ++ [:id, :inserted_at]}

  schema "messaging__text_messages" do
    # incoming, outgoing [AppRent sent or received]
    field :direction, :string
    # The number that sent the message
    field :from_number, :string
    field :to_number, :string
    field :body, :string
    # if MMS, generally jpeg/jpg
    field :media_types, {:array, :string}
    # link to the actual files if mms
    field :media_urls, {:array, :string}
    # Twilio SmsSid
    field :external_id, :string
    # Twilio SmsStatus [received, could be others]
    field :status, :string
    field :extra_params, :map, default: %{}

    timestamps()
  end

  @doc false
  def changeset(text_message, attrs) do
    text_message
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
  end
end
