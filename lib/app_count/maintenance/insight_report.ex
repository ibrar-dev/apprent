defmodule AppCount.Maintenance.InsightReport do
  alias AppCount.Properties.Property
  use Ecto.Schema
  import Ecto.Changeset

  schema "maintenance__insight_reports" do
    field :data, :map
    field :end_time, :utc_datetime
    field :start_time, :utc_datetime
    field :type, :string, default: "daily"
    # "version" determines which show#{version}.html.eex" to use when rendering
    # change default when removeing fields from the JSON
    field :version, :integer, default: 1

    belongs_to :property, Property

    timestamps()
  end

  @doc false
  def changeset(insight_report, attrs) do
    insight_report
    |> cast(attrs, [:type, :data, :start_time, :end_time, :property_id])
    |> validate_required([:type, :data, :start_time, :end_time, :property_id])
    |> validate_inclusion(:type, ["daily", "weekly"])
  end

  def template_name(%{version: version}) do
    "ver#{version}/show.html"
  end
end
