defmodule AppCount.Maintenance.InsightReports.WorkOrderViolationsProbe do
  import Ecto.Query
  alias AppCount.Repo
  alias AppCount.Maintenance.Order

  use AppCount.Maintenance.InsightReports.ProbeBehaviour

  @moduledoc """
  Given property and moment_in_time, find all open "Violation"-level work orders
  as of moment_in_time.
  """

  @impl ProbeBehaviour
  def mood, do: :negative

  @impl ProbeBehaviour
  def insight_item(%ProbeContext{} = context) do
    reading = reading(context)
    comments = comments(reading.value)

    %InsightItem{
      comments: comments,
      reading: reading,
      meta: %{mood: mood(), reporter: __MODULE__}
    }
  end

  @impl ProbeBehaviour
  def reading(%ProbeContext{input: %{property: property}}) do
    violations_count = call(property)
    Reading.work_order_violations(violations_count)
  end

  def comments(violations_count) do
    cond do
      violations_count == 1 ->
        [
          "Urgent! There is 1 open City Code violation. Please resolve this as quickly as possible."
        ]

      violations_count > 1 ->
        [
          "Urgent! There are #{violations_count} open City Code violations. Please resolve these as quickly as possible."
        ]

      true ->
        []
    end
  end

  def call(property) do
    violation_level = 3

    # TODO lift this up the stack and into @deps
    work_order_count =
      Repo.one(
        from o in Order,
          where:
            o.property_id == ^property.id and
              o.status in ["unassigned", "assigned"] and
              o.priority in [^violation_level],
          select: count(o.id)
      )

    # Vendor orders must also be counted here -- we query for and count them
    # differently, much to everyone's dismay
    #
    # Vendor Orders have a `property_id` field, but it's not populated --
    # instead we join on the unit, if one exists
    # TODO lift this up the stack and into @deps
    vendor_order_count =
      Repo.one(
        from v in AppCount.Vendors.Order,
          join: u in assoc(v, :unit),
          join: c in assoc(v, :category),
          where:
            (u.property_id == ^property.id or v.property_id == ^property.id) and
              v.status == "Open" and
              c.name != "Make Ready" and
              v.priority in [^violation_level],
          select: count(v.id)
      )

    # Wrap it up and put a bow on it
    work_order_count + vendor_order_count
  end
end
