defmodule AppCount.Socials.Post do
  use Ecto.Schema
  import Ecto.Changeset
  alias AppCount.Socials.Post

  schema "social__posts" do
    field(:text, :string)
    field(:history, {:array, :map})
    belongs_to(:tenant, Module.concat(["AppCount.Tenants.Tenant"]))
    belongs_to(:property, Module.concat(["AppCount.Properties.Property"]))
    has_many(:likes, Module.concat(["AppCount.Socials.Like"]))
    has_many(:reports, Module.concat(["AppCount.Socials.Report"]))
    field(:visible, :boolean)

    timestamps()
  end

  @doc false
  def changeset(%Post{} = post, attrs) do
    post
    |> cast(attrs, [:text, :history, :tenant_id, :property_id, :visible])
    |> validate_required([:text, :tenant_id, :property_id])
  end
end
