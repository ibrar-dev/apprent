defmodule AppCount.Maintenance.InsightReports.PerformancePointsTest do
  use AppCount.ProbeCase
  alias AppCount.Maintenance.InsightReports.PerformancePoints, as: Points

  describe "scoring edge cases" do
    test "work_order_turnaround" do
      # When
      assert 15 == Points.work_order_turnaround({0, :days})
      assert 15 == Points.work_order_turnaround({0.999, :days})
      assert 12 == Points.work_order_turnaround({1, :days})
      assert 12 == Points.work_order_turnaround({1.999, :days})
      assert 10 == Points.work_order_turnaround({2, :days})
      assert 10 == Points.work_order_turnaround({2.999, :days})
      assert 5 == Points.work_order_turnaround({3, :days})
      assert 5 == Points.work_order_turnaround({3.999, :days})
      assert 2 == Points.work_order_turnaround({4, :days})
      assert 2 == Points.work_order_turnaround({4.999, :days})
      assert 0 == Points.work_order_turnaround({5, :days})
      assert 0 == Points.work_order_turnaround({5.001, :days})
    end

    test "make_ready_turnaround" do
      assert 0 == Points.make_ready_turnaround({0, :days})
      assert 15 == Points.make_ready_turnaround({0.01, :days})
      assert 15 == Points.make_ready_turnaround({4.99, :days})
      assert 15 == Points.make_ready_turnaround({5, :days})
      assert 12.01 == Points.make_ready_turnaround({7.99, :days})
      assert 12 == Points.make_ready_turnaround({8, :days})
      assert 11.98 == Points.make_ready_turnaround({8.01, :days})
    end

    test "make_ready_percent" do
      assert 0.0 == Points.make_ready_percent({0, :percent})
      assert 0.0 == Points.make_ready_percent({49.99, :percent})
      assert 0.0 == Points.make_ready_percent({50, :percent})
      assert 0.5 == Points.make_ready_percent({51, :percent})
      assert 1.0 == Points.make_ready_percent({52, :percent})
      assert 1.5 == Points.make_ready_percent({53, :percent})
      assert 2.5 == Points.make_ready_percent({55, :percent})
      assert 14.5 == Points.make_ready_percent({79, :percent})
      assert 15.0 == Points.make_ready_percent({80, :percent})
      assert 15.0 == Points.make_ready_percent({81, :percent})
    end
  end
end
