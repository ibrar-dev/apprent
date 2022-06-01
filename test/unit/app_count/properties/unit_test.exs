defmodule AppCount.Properties.UnitTest do
  use AppCount.DataCase
  alias AppCount.Properties.Unit
  alias AppCount.Leases.Lease
  alias AppCount.Core.DateTimeRange

  def yesterday() do
    Clock.today({-1, :days})
  end

  describe "current_leases/2 DateRange" do
    setup do
      builder =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()
        |> PropBuilder.add_unit()
        |> PropBuilder.add_tenant()
        |> PropBuilder.add_lease()

      lease = PropBuilder.get_requirement(builder, :lease)
      unit = PropBuilder.get_requirement(builder, :unit)
      today_range = DateTimeRange.today()

      ~M[builder, lease, unit, today_range]
    end

    test "find current", ~M[lease, unit, today_range] do
      unit = AppCount.Repo.preload(unit, :leases)

      # When
      [result_lease] = Unit.current_leases(unit, today_range)

      assert result_lease.id == lease.id
    end

    test "find multiple over last30days", ~M[builder, lease, unit] do
      recent_lease = lease

      lease_attrs = [
        start_date: AppCount.current_date() |> Timex.shift(years: -1),
        end_date: AppCount.current_date() |> Timex.shift(days: -10),
        actual_move_in: AppCount.current_date() |> Timex.shift(years: -1),
        actual_move_out: AppCount.current_date() |> Timex.shift(days: -10)
      ]

      builder =
        builder
        |> PropBuilder.add_tenant()
        |> PropBuilder.add_lease(lease_attrs)

      previous_lease = PropBuilder.get_requirement(builder, :lease)

      unit = AppCount.Repo.preload(unit, :leases)
      last30days = DateTimeRange.last30days()

      # When
      result = Unit.current_leases(unit, last30days)
      # Then
      assert length(result) == 2
      [lease_one, lease_two] = result
      assert lease_one.id == recent_lease.id
      assert lease_two.id == previous_lease.id
    end

    test "return []. nothing current, has renewal", ~M[lease, unit, today_range] do
      _lease =
        update_lease(lease, %{renewal_id: lease.id})
        |> AppCount.Repo.preload(:renewal)

      unit = AppCount.Repo.preload(unit, :leases)

      # When
      result_lease_not_found = Unit.current_leases(unit, today_range)
      assert [] == result_lease_not_found
    end

    test "return []. nothing current, has actual_move_out", ~M[lease, unit, today_range] do
      _lease = update_lease(lease, %{actual_move_out: yesterday()})

      unit = AppCount.Repo.preload(unit, :leases)

      # When
      result_lease_not_found = Unit.current_leases(unit, today_range)
      assert [] == result_lease_not_found
    end

    test "return []. nothing current, has future start date", ~M[lease, unit, today_range] do
      future_date = Clock.today({5, :days})
      _lease = update_lease(lease, %{start_date: future_date})

      unit = AppCount.Repo.preload(unit, :leases)

      # When
      result_lease_not_found = Unit.current_leases(unit, today_range)
      assert [] == result_lease_not_found
    end
  end

  describe "current_lease/2" do
    setup do
      builder =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()
        |> PropBuilder.add_unit()
        |> PropBuilder.add_tenant()
        |> PropBuilder.add_lease()

      lease = PropBuilder.get_requirement(builder, :lease)
      unit = PropBuilder.get_requirement(builder, :unit)

      ~M[builder, lease, unit]
    end

    test "find current", ~M[lease, unit] do
      unit = AppCount.Repo.preload(unit, :leases)

      # When
      result_lease = %AppCount.Leases.Lease{} = Unit.current_lease(unit, Clock.today())
      assert result_lease.id == lease.id
    end

    test "return nil. nothing current, has renewal", ~M[lease, unit] do
      _lease =
        update_lease(lease, %{renewal_id: lease.id})
        |> AppCount.Repo.preload(:renewal)

      unit = AppCount.Repo.preload(unit, :leases)

      # When
      result_lease_not_found = Unit.current_lease(unit, Clock.today())
      assert nil == result_lease_not_found
    end

    test "return nil. nothing current, has actual_move_out", ~M[lease, unit] do
      _lease = update_lease(lease, %{actual_move_out: yesterday()})

      unit = AppCount.Repo.preload(unit, :leases)

      # When
      result_lease_not_found = Unit.current_lease(unit, Clock.today())
      assert nil == result_lease_not_found
    end

    test "return nil. nothing current, has future start date", ~M[lease, unit] do
      future_date = Clock.today({5, :days})
      _lease = update_lease(lease, %{start_date: future_date})

      unit = AppCount.Repo.preload(unit, :leases)

      # When
      result_lease_not_found = Unit.current_lease(unit, Clock.today())
      assert nil == result_lease_not_found
    end
  end

  defp update_lease(%Lease{} = lease, params) do
    {:ok, lease} =
      lease
      |> Lease.changeset(params)
      |> Repo.update()

    lease
  end
end
