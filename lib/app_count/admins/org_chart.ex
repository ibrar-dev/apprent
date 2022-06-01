defmodule AppCount.Admins.OrgChart do
  use Ecto.Schema
  use EctoMaterializedPath
  import Ecto.Changeset

  schema "admins__org_charts" do
    field :path, EctoMaterializedPath.Path, default: []
    field :status, :string, default: "available"
    belongs_to :admin, Module.concat(["AppCount.Admins.Admin"])

    timestamps()
  end

  @doc false
  def changeset(org_chart, attrs) do
    org_chart
    |> cast(attrs, [:path, :status, :admin_id])
    |> validate_required([:path, :admin_id])
    |> unique_constraint(:admin_id)
    |> validate_exclusion(:status, ["available", "away"])
  end
end
