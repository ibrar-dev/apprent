defmodule AppCount.ProbeCase do
  @moduledoc """
  """
  use ExUnit.CaseTemplate

  using do
    quote do
      use AppCount.DataCase
      alias AppCount.Properties.Property
      alias AppCount.Maintenance.Assignment
      alias AppCount.Maintenance.Order
      alias AppCount.Properties.Unit
      alias AppCount.Maintenance.Tech
      alias AppCount.Core.DateTimeRange
      alias AppCount.Maintenance.InsightReports.Daily
      alias AppCount.Maintenance.InsightReports.ProbeContext
      alias AppCount.Maintenance.Reading

      defmodule ProbeParrot do
        use TestParrot
        @behaviour AppCount.Maintenance.InsightReports.ProbeBehaviour
        parrot(:reporter, :call, [])
        parrot(:reporter, :insight_item, AppCount.Maintenance.InsightItem.new())
        parrot(:reporter, :mood, :neutral)
        parrot(:reporter, :reading, %AppCount.Maintenance.Reading{})
      end
    end
  end

  setup do
    AppCount.DataCase.load_ecto_sandbox()
    alias AppCount.Support.PropertyBuilder, as: PropBuilder
    today_range = AppCount.Core.DateTimeRange.today()

    property =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.get_requirement(:property)

    assignments = %{
      one: %AppCount.Maintenance.Assignment{
        order: %AppCount.Maintenance.Order{id: 15, unit: %AppCount.Properties.Unit{number: "ABC"}},
        tech: %AppCount.Maintenance.Tech{name: "Ringo"}
      }
    }

    %{today_range: today_range, property: property, assignments: assignments}
  end
end
