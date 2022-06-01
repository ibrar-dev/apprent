defmodule AppCount.Properties.ResidentEvent do
  use Ecto.Schema
  import Ecto.Changeset
  use AppCount.EctoTypes.Attachment

  schema "properties__resident_events" do
    field :info, :string
    field :location, :string
    field :name, :string
    field :date, :date
    field :start_time, :integer
    field :end_time, :integer
    field :admin, :string
    attachment(:image)
    attachment(:attachment)
    belongs_to(:property, Module.concat(["AppCount.Properties.Property"]))

    has_many(:attendees, Module.concat(["AppCount.Properties.ResidentEventAttendance"]),
      foreign_key: :tenant_id
    )

    timestamps()
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [:location, :name, :info, :date, :start_time, :end_time, :admin, :property_id])
    |> cast_attachment(:attachment, public: true)
    |> cast_attachment(:image, public: true)
    |> validate_required([:name, :date, :start_time, :property_id, :admin])
  end
end
