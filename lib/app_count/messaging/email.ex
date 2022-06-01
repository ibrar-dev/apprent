defmodule AppCount.Messaging.Email do
  use Ecto.Schema
  import Ecto.Changeset
  import AppCount.EctoTypes.Upload

  schema "messaging__emails" do
    field :attachments, {:array, upload_type("appcount-messaging:emails", "attachment")}
    field :body, upload_type("appcount-messaging:emails", "body")
    field :to, :string
    field :from, :string, default: "admin@apprent.com"
    field :subject, :string
    belongs_to :tenant, Module.concat(["AppCount.Tenants.Tenant"])

    timestamps()
  end

  def changeset(email, attrs) do
    email
    |> cast(attrs, [:subject, :body, :attachments, :tenant_id, :to, :from])
    |> validate_required([:subject, :body, :tenant_id, :to])
  end
end
