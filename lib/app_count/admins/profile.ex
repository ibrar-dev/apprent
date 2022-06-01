defmodule AppCount.Admins.Profile do
  use Ecto.Schema
  import Ecto.Changeset
  use AppCount.EctoTypes.Attachment

  # the plug is using maintenance bc when it was appcount-admins:profile_images it did not work
  schema "admins__profiles" do
    field :bio, :string
    field :active, :boolean
    field :title, :string
    attachment(:image)
    belongs_to :admin, Module.concat(["AppCount.Admins.Admin"])

    timestamps()
  end

  @doc false
  def changeset(profile, attrs) do
    profile
    |> cast(attrs, [:bio, :active, :admin_id, :title])
    |> cast_attachment(:image, public: true)
    |> validate_required([:admin_id])
    |> unique_constraint(:admin, [:admin_id])
  end
end
