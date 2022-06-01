defmodule AppCount.Maintenance.InsightReportsTest do
  use AppCount.DataCase
  alias AppCount.Maintenance.InsightReports
  alias AppCount.Maintenance.InsightReport
  alias AppCount.Core.ClientSchema

  setup do
    now = Timex.now()

    builder =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()

    property = PropBuilder.get_requirement(builder, :property)
    ~M[now, builder, property]
  end

  describe "create_report" do
    setup(%{property: property, now: now}) do
      report = create_report(property, now)
      ~M[report]
    end

    test "version", ~M[report] do
      assert 1 == report.version
    end

    test "template_name version 1", ~M[report] do
      assert "ver1/show.html" == InsightReport.template_name(report)
    end

    test "template_name version 2", ~M[report] do
      report = %{report | version: 2}
      assert "ver2/show.html" == InsightReport.template_name(report)
    end
  end

  test "returns an empty list if none exist", ~M[ property] do
    result =
      InsightReports.index(%{
        property_ids: [property.id]
      })

    assert Enum.empty?(result)
  end

  describe "index/2 daily and weekly reports exist" do
    setup(%{property: property, now: now}) do
      daily_report = create_report(property, now, %{type: "daily"})
      weekly_report = create_report(property, now, %{type: "weekly"})
      ~M[daily_report, weekly_report]
    end

    test "filters by type - daily", ~M[ property, daily_report] do
      result =
        InsightReports.index(%{
          property_ids: [property.id],
          type: "daily"
        })

      assert length(result) == 1

      [r] = result

      assert r.id == daily_report.id
    end

    test "filters by type - weekly", ~M[ property, weekly_report] do
      result =
        InsightReports.index(%{
          property_ids: [property.id],
          type: "weekly"
        })

      assert length(result) == 1

      [r] = result

      assert r.id == weekly_report.id
    end

    test "filters by type - both as empty string", ~M[ property] do
      result =
        InsightReports.index(%{
          property_ids: [property.id],
          type: ""
        })

      assert length(result) == 2
    end

    test "filters by type - both as nil type", ~M[ property] do
      result =
        InsightReports.index(%{
          property_ids: [property.id],
          type: nil
        })

      assert length(result) == 2
    end

    test "missing type param returns all", ~M[ property] do
      result =
        InsightReports.index(%{
          property_ids: [property.id]
        })

      assert length(result) == 2
    end
  end

  describe "index/2" do
    test "returns an empty list if no properties", ~M[builder, now, property] do
      create_report(property, now)

      new_property =
        builder
        |> PropBuilder.add_property()
        |> PropBuilder.get_requirement(:property)

      create_report(new_property, now)

      result =
        InsightReports.index(%{
          property_ids: []
        })

      assert [] == result
    end

    test "filters by issue date - start date", ~M[now, property] do
      in_range_report = create_report(property, now)
      _out_of_range_report = create_report(property, Timex.shift(now, days: -7))

      start_date =
        now
        |> Timex.to_date()

      result =
        InsightReports.index(%{
          property_ids: [property.id],
          start_date: start_date
        })

      assert length(result) == 1
      found_id = hd(result).id

      assert found_id == in_range_report.id
    end

    test "returns all reports if nil property_ids", ~M[builder, now, property] do
      create_report(property, now)

      new_property =
        builder
        |> PropBuilder.add_property()
        |> PropBuilder.get_requirement(:property)

      create_report(new_property, now)

      result = InsightReports.index()

      assert length(result) == 2
    end

    test "returns all that exist for a property", ~M[now, builder, property] do
      create_report(property, now)

      new_property =
        builder
        |> PropBuilder.add_property()
        |> PropBuilder.get_requirement(:property)

      new_report = create_report(new_property, now)

      result =
        InsightReports.index(%{
          property_ids: [new_property.id]
        })

      [r] = result

      assert r.id == new_report.id
    end

    test "returns all that exist for multiple properties", ~M[now, builder, property] do
      original_report = create_report(property, now)

      new_property =
        builder
        |> PropBuilder.add_property()
        |> PropBuilder.get_requirement(:property)

      new_report = create_report(new_property, now)

      result =
        InsightReports.index(%{
          property_ids: [property.id, new_property.id]
        })

      assert length(result) == 2

      ids = Enum.map(result, fn r -> r.id end)

      assert original_report.id in ids
      assert new_report.id in ids
    end

    test "filters by issue date - end date", ~M[now, property] do
      _out_of_range_report = create_report(property, now)
      in_range_report = create_report(property, Timex.shift(now, days: -7))

      # Shift back to before `out_of_range_report` is effective
      end_date =
        now
        |> Timex.shift(days: -1)
        |> Timex.to_date()

      result =
        InsightReports.index(%{
          property_ids: [property.id],
          end_date: end_date
        })

      assert length(result) == 1
      found_id = hd(result).id

      assert found_id == in_range_report.id
    end

    test "filters by issue date - start and end date", ~M[now,  property] do
      # Goldilocks-style setup
      _too_early_report = create_report(property, Timex.shift(now, days: -7))
      _too_late_report = create_report(property, now)
      just_right_report = create_report(property, Timex.shift(now, days: -3))

      start_date =
        now
        |> Timex.shift(days: -5)
        |> Timex.to_date()

      end_date =
        now
        |> Timex.shift(days: -2)
        |> Timex.to_date()

      result =
        InsightReports.index(%{
          property_ids: [property.id],
          start_date: start_date,
          end_date: end_date
        })

      assert length(result) == 1
      found_id = hd(result).id

      assert found_id == just_right_report.id
    end

    test "filter with missing issue-date flags", ~M[now, property] do
      create_report(property, now, %{type: "daily"})

      result =
        InsightReports.index(%{
          property_ids: [property.id],
          start_date: nil,
          end_date: nil
        })

      assert length(result) == 1
    end
  end

  describe "create/1" do
    test "creates in valid state", ~M[builder, now] do
      {start_time, end_time} = start_and_end_times(now)

      data = %{some: "data"}

      property =
        builder
        |> PropBuilder.get_requirement(:property)

      attrs = %{
        start_time: start_time,
        end_time: end_time,
        data: data,
        property_id: property.id
      }

      assert {:ok, _report} = InsightReports.create(ClientSchema.new("dasmen", attrs))
    end
  end

  describe "fetch/1" do
    test "finds a report", ~M[builder, now] do
      property =
        builder
        |> PropBuilder.get_requirement(:property)

      report = create_report(property, now)

      %InsightReport{id: id} = result = InsightReports.fetch(report.id)

      assert result
      assert id == report.id
    end

    test "finds a report and atomizes keys for data", ~M[builder, now] do
      property =
        builder
        |> PropBuilder.get_requirement(:property)

      report = create_report(property, now, %{data: %{"foo" => %{"bar" => 123}}})

      result = InsightReports.fetch(report.id)

      # This type of access requires atom keys
      assert result.data.foo.bar == 123
    end

    test "fails to find a report" do
      result = InsightReports.fetch(0)

      assert is_nil(result)
    end
  end

  def create_report(property, now, args \\ %{}) do
    {start_time, end_time} = start_and_end_times(now)

    data = %{some: "data"}

    attrs =
      %{
        start_time: start_time,
        end_time: end_time,
        data: data,
        type: "daily",
        property_id: property.id
      }
      |> Map.merge(args)

    {:ok, report} = InsightReports.create(ClientSchema.new("dasmen", attrs))

    report
  end

  def start_and_end_times(time) do
    end_time =
      time
      |> Timex.set(hour: 17, minute: 0, second: 0)

    start_time =
      end_time
      |> Timex.shift(days: -1)

    {start_time, end_time}
  end
end
