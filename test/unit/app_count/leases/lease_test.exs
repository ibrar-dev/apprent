defmodule AppCount.Leases.LeaseTest do
  use AppCount.DataCase
  alias AppCount.Leases.Lease

  describe "current?/1" do
    setup do
      times =
        AppTime.new()
        |> AppTime.plus_to_date(:yesterday, days: -1)
        |> AppTime.plus_to_date(:today, days: 0)
        |> AppTime.plus_to_date(:tomorrow, days: 1)
        |> AppTime.times()

      lease = %Lease{start_date: times.today}

      ~M[times, lease]
    end

    test "in force today", ~M[times, lease] do
      result = Lease.current?(lease, times.today)
      assert result
    end

    test "will be in force tomorrow", ~M[times, lease] do
      result = Lease.current?(lease, times.tomorrow)
      assert result
    end

    test "not in force yesterday", ~M[times, lease] do
      result = Lease.current?(lease, times.yesterday)
      refute result
    end

    test "not in force: actual_move_out", ~M[times, lease] do
      lease = %{lease | actual_move_out: times.yesterday}
      result = Lease.current?(lease, times.today)
      refute result
    end

    test "not in force: end_date", ~M[times, lease] do
      lease = %{lease | end_date: times.yesterday}
      result = Lease.current?(lease, times.today)
      refute result
    end
  end

  describe "pending?/1" do
    setup do
      times =
        AppTime.new()
        |> AppTime.plus_to_date(:today, days: 0)
        |> AppTime.plus_to_date(:tomorrow, days: 1)
        |> AppTime.times()

      lease = %Lease{start_date: times.today}

      ~M[times, lease]
    end

    test "pending", ~M[times, lease] do
      lease = %{lease | start_date: times.tomorrow}

      result = Lease.pending?(lease, times.today)
      assert result
    end

    test "not pending ", ~M[times, lease] do
      result = Lease.pending?(lease, times.today)
      refute result
    end
  end
end
