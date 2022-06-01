defmodule AppCount.Messaging.Mailing do
  use Ecto.Schema
  import Ecto.Changeset
  import AppCount.EctoTypes.Upload

  schema "messaging__mailings" do
    field :recipients, {:array, :map}
    field :subject, :string
    field :body, :string
    field :attachments, {:array, upload_type("appcount-messaging:emails", "attachment")}
    field :property_ids, {:array, :integer}
    field :sender, :string
    field :next_run, :integer
    field :send_at, :map

    timestamps()
  end

  @doc false
  def changeset(mailing, attrs) do
    mailing
    |> cast(attrs, [
      :send_at,
      :recipients,
      :subject,
      :body,
      :attachments,
      :property_ids,
      :sender,
      :next_run
    ])
    |> validate_required([:recipients, :subject, :body, :attachments, :property_ids, :sender])
  end
end
