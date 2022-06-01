defmodule AppCount.Maintenance.InsightReportSubscription do
  use Ecto.Schema
  import Ecto.Changeset

  schema "maintenance__insight_report_subscriptions" do
    # Type is daily or weekly
    field :type, :string, default: "daily"

    belongs_to(:admin, AppCount.Admins.Admin)
    belongs_to(:property, AppCount.Properties.Property)

    timestamps()
  end

  @doc false
  def changeset(insight_report_subscription, attrs) do
    insight_report_subscription
    |> cast(attrs, [:type, :property_id, :admin_id])
    |> validate_required([:type, :property_id, :admin_id])
    |> validate_inclusion(:type, ["daily", "weekly"])
  end
end
