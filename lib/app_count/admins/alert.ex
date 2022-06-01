defmodule AppCount.Admins.Alert do
  use Ecto.Schema
  import Ecto.Changeset
  use AppCount.EctoTypes.Attachment

  schema "admins__alerts" do
    field :flag, :integer, default: 1
    field :note, :string
    field :read, :boolean, default: false
    field :sender, :string, default: "AppRent"
    field :history, {:array, :map}, default: []
    attachment(:attachment)
    belongs_to(:admin, AppCount.Admins.Admin)

    timestamps()
  end

  @doc false
  def changeset(alert, attrs) do
    alert
    |> cast(attrs, [:note, :sender, :read, :flag, :admin_id, :history, :inserted_at])
    |> cast_attachment(:attachment)
    |> validate_required([:note, :sender, :read, :flag, :admin_id, :history])
  end
end
