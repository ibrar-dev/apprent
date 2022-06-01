defmodule AppCount.Socials.Like do
  use Ecto.Schema
  import Ecto.Changeset
  alias AppCount.Socials.Like

  schema "social__posts_likes" do
    belongs_to(:tenant, Module.concat(["AppCount.Tenants.Tenant"]))
    belongs_to(:post, Module.concat(["AppCount.Socials.Post"]))

    timestamps()
  end

  @doc false
  def changeset(%Like{} = likes, attrs) do
    likes
    |> cast(attrs, [:tenant_id, :post_id])
    |> validate_required([:tenant_id, :post_id])
  end
end
