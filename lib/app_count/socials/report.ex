defmodule AppCount.Socials.Report do
  use Ecto.Schema
  import Ecto.Changeset

  schema "social__reports" do
    field(:reason, :string)
    belongs_to(:admin, Module.concat(["AppCount.Admins.Admin"]))
    belongs_to(:tenant, Module.concat(["AppCount.Tenants.Tenant"]))
    belongs_to(:post, Module.concat(["AppCount.Socials.Post"]))

    timestamps()
  end

  @doc false
  def changeset(report, attrs) do
    report
    |> cast(attrs, [:reason, :tenant_id, :admin_id, :post_id])
    |> validate_required([:reason, :post_id, :tenant_id])
  end
end
