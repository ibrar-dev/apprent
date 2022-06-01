defmodule AppCount.Properties.ResidentEventAttendance do
  use Ecto.Schema
  import Ecto.Changeset

  schema "properties__resident_event_attendances" do
    belongs_to :resident_event, Module.concat(["AppCount.Properties.ResidentEvent"])
    belongs_to :tenant, Module.concat(["AppCount.Tenants.Tenant"])

    timestamps()
  end

  @doc false
  def changeset(resident_event_attendance, attrs) do
    resident_event_attendance
    |> cast(attrs, [:resident_event_id, :tenant_id])
    |> unique_constraint(:tenant_id)
    |> validate_required([:resident_event_id, :tenant_id])
  end
end
