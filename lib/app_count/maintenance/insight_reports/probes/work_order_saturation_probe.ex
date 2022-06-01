defmodule AppCount.Maintenance.InsightReports.WorkOrderSaturationProbe do
  alias AppCount.Properties.Property
  use AppCount.Maintenance.InsightReports.ProbeBehaviour

  @doc """
  Given a property, figure out "saturation", that is, the number of open work
  orders divided by the number of units. This gives us a ratio of orders to
  unit, which we'd like to keep as low as possible (by way of minimizing
  orders).

  Returns {12.34, 7, :percent} -- the first number is the percentage, the second
  is the number of open orders, and the third is the value type.
  """

  @impl ProbeBehaviour
  def mood, do: :neutral

  @impl ProbeBehaviour
  def insight_item(
        %ProbeContext{
          input: %{
            property: property,
            open_orders: open_orders,
            open_vendor_orders: open_vendor_orders
          }
        } = context
      ) do
    {saturation, order_count, :percent} = call(property, open_orders, open_vendor_orders)

    comments = comments(saturation, order_count)
    reading = reading(context)

    %InsightItem{
      comments: comments,
      reading: reading,
      meta: %{mood: mood(), reporter: __MODULE__}
    }
  end

  @impl ProbeBehaviour
  def reading(%ProbeContext{
        input: %{
          property: property,
          open_orders: open_orders,
          open_vendor_orders: open_vendor_orders
        }
      }) do
    {saturation, _order_count, :percent} = call(property, open_orders, open_vendor_orders)
    Reading.work_order_saturation(saturation)
  end

  def call(%Property{} = property, open_orders, open_vendor_orders) do
    unit_count = length(property.units)
    order_count = length(open_orders)
    vendor_orders_count = length(open_vendor_orders)

    total_order_count = vendor_orders_count + order_count
    percent = divide(total_order_count, unit_count) * 100

    {percent, order_count, :percent}
  end

  def divide(_order_count, 0) do
    0.0
  end

  def divide(order_count, unit_count) do
    order_count / unit_count
  end

  @doc """
  If we have 5% or less saturation (ratio of open orders to units for a
  property), we want to give a shoutout.

  If we have 10% or greater saturation, we want to comment that things can
  improve.

  If we are within that range, we don't say anything. Everything is fine.
  """
  def comments(saturation, order_count) do
    cond do
      is_binary(saturation) ->
        []

      saturation <= 5 ->
        str = "#{superlative()} job keeping work orders low!"
        [str]

      saturation >= 10 ->
        str =
          "Work orders are looking too high with #{order_count} open. Let's work to bring them down. You got this!"

        [str]

      true ->
        []
    end
  end

  def superlative() do
    [
      "Amazing",
      "Awesome",
      "Excellent",
      "Fantastic",
      "Great",
      "Incredible",
      "Stupendous",
      "Super",
      "Wonderful"
    ]
    |> Enum.random()
  end
end
