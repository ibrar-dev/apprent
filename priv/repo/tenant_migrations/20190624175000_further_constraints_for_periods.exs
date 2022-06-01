defmodule AppCount.Repo.Migrations.FurtherConstraintsForPeriods do
  use Ecto.Migration

  def change do
    exclude = ~s|gist (property_id WITH =, daterange("start_date", "end_date") WITH &&)|
    create constraint(:leases__renewal_periods, :period_overlap, exclude: exclude)
  end
end
