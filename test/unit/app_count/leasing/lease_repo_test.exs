defmodule AppCount.Leasing.LeaseRepoTest do
  use AppCount.DataCase

  test "most_current_lease_query" do
    today = AppCount.current_date()

    lease1 =
      insert(
        :leasing_lease,
        start_date: Timex.shift(today, years: -2),
        end_date: Timex.shift(today, years: -1)
      )

    lease2 =
      insert(
        :leasing_lease,
        start_date: Timex.shift(lease1.end_date, days: 1),
        end_date: Timex.shift(lease1.end_date, days: 366),
        customer_ledger: lease1.customer_ledger
      )

    lease3 =
      insert(
        :leasing_lease,
        start_date: Timex.shift(lease1.end_date, days: 1),
        end_date: Timex.shift(lease1.end_date, days: 366)
      )

    # When
    current_leases =
      AppCount.Leasing.LeaseRepo.most_current_lease_query()
      |> Repo.all()

    assert Enum.any?(current_leases, &(&1.id == lease2.id))
    assert Enum.any?(current_leases, &(&1.id == lease3.id))
    refute Enum.any?(current_leases, &(&1.id == lease1.id))
  end
end
