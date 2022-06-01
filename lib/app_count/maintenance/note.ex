defmodule AppCount.Maintenance.Note do
  use Ecto.Schema
  import Ecto.Changeset
  alias AppCount.Maintenance.Note
  use AppCount.EctoTypes.Attachment
  # TODO do we want to replace with POISON?
  @derive {Jason.Encoder,
   only: [
     :id,
     :text,
     :order_id,
     :inserted_at,
     :tenant,
     :admin,
     :tech,
     :attachment,
     :attachment_url,
     #  This appears to be only associated with notes created by techs
     :image
   ]}

  schema "maintenance__notes" do
    field(:image, :string)
    field(:text, :string)
    field(:visible_to_resident, :boolean)
    belongs_to(:tenant, AppCount.Tenants.Tenant)
    belongs_to(:admin, AppCount.Admins.Admin)
    belongs_to(:tech, AppCount.Maintenance.Tech)
    belongs_to(:order, AppCount.Maintenance.Order)
    attachment(:attachment)

    timestamps()
  end

  @doc false
  def changeset(%Note{} = note, attrs) do
    note
    |> cast(attrs, [
      :text,
      :image,
      :tenant_id,
      :admin_id,
      :order_id,
      :tech_id,
      :visible_to_resident
    ])
    |> cast_attachment(:attachment)
    |> validate_required([:order_id])
    |> check_constraint(:tenant_id, name: :must_have_assigner)
    |> check_constraint(:text, name: :must_have_body)
  end

  def image_url(%{image: img} = note) when is_binary(img) do
    env = AppCount.env()[:environment]
    "https://s3-us-east-2.amazonaws.com/appcount-maintenance/notes/#{env}/#{note.id}/#{img}"
  end

  def image_url(_), do: nil
end
