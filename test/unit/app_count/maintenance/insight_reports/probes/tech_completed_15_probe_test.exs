defmodule AppCount.Maintenance.InsightReports.TechCompleted15ProbeTest do
  use AppCount.ProbeCase
  alias AppCount.Maintenance.InsightReports.TechCompleted15Probe

  def build_assignments(count, tech_name) do
    now = DateTime.utc_now()

    1..count
    |> Enum.reduce([], fn _num, acc ->
      assignment = %Assignment{tech: %Tech{name: tech_name}, completed_at: now}
      [assignment | acc]
    end)
  end

  describe "has assignments and techs" do
    test "no tech has 15+ assignments" do
      # When
      messages = TechCompleted15Probe.call(build_assignments(14, "Ringo"))

      assert messages == []
    end

    test "Ringo had 15 completed assignments" do
      # When
      messages = TechCompleted15Probe.call(build_assignments(15, "Ringo"))

      assert messages == [
               "Special shout-out to Ringo who completed 15 work orders today!"
             ]
    end

    test "Ringo and John both completed lots of assignments" do
      assignments =
        build_assignments(15, "Ringo") ++
          build_assignments(22, "John") ++
          build_assignments(1, "Paul")

      # When
      messages = TechCompleted15Probe.call(assignments)

      assert messages == [
               "Special shout-out to Ringo who completed 15 work orders today!",
               "Special shout-out to John who completed 22 work orders today!"
             ]
    end
  end
end
