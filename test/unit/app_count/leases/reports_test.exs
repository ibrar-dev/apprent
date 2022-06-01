defmodule AppCount.Leases.ReportsTest do
  use AppCount.DataCase
  alias AppCount.Leases

  @moduletag :leases_reports

  test "get_leases" do
    lease = AppCount.LeaseHelper.insert_lease()
    start_date = Timex.shift(lease.inserted_at, days: -1)
    end_date = Timex.shift(lease.inserted_at, days: 1000)
    [result] = Leases.get_leases(lease.unit.property_id, start_date, end_date)
    assert result.unit == lease.unit.number
    assert length(result.tenants) == 1
    assert result.start_date == lease.start_date
  end

  test "renewal_report" do
    today = AppCount.current_date()

    lease =
      AppCount.LeaseHelper.insert_lease(%{
        start_date: today,
        end_date: Timex.shift(today, days: 100)
      })

    insert(:renewal_period, property: lease.unit.property, approval_date: nil)

    admin = AppCount.UserHelper.new_admin(%{roles: ["Super Admin"]})

    assert Leases.renewal_report(admin, lease.unit.property_id) == %{
             leases_needing_renewals: 1,
             pending_periods: 1
           }
  end
end
