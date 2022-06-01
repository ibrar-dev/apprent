defmodule AppCount.Maintenance.InsightReports.InsightReportFormatter do
  alias AppCount.Maintenance.InsightReports.Duration

  @moduledoc """
  We have a number of different ways we might format our data values, depending
  on the contents of the data struct.
  Mandatory fields are:
  + display
  + title
  + value
  We have an optional field of `tag`
  We use `display` to know how to interpret and format `value` -- if tag is
  present, it gets appended in parentheses.
  For example:
  %{
    display: "rating",
    tag: "last 30 days",
    title: "Average Maintenance Rating",
    value: 3.9123234
  }
  Becomes: "3.9/5.0 (last 30 days)"
  If `tag` were missing, it'd be just "3.9/5.0"
  If `value` is missing, we typically replace with `N/A`
  All numbers are represented as either integers or floats with a single point
  of precision (e.g. 12.3). We round to the nearest tenth when necessary.
  """

  # Return "N/A" for any display for which value is nil
  def format(%{value: nil}) do
    "N/A"
  end

  def format(%{value: value}) when is_binary(value) do
    "N/A"
  end

  # %{
  #   display: duration,
  #   value: 84600,
  #   tag: "jobs completed in last 24 hours",
  #   title: "Average Completion Time",
  # }
  #
  # Value is duration in seconds

  # Duration < 1 day - format in hours
  def format(%{display: "duration", value: value} = datum) do
    val = {value, :seconds} |> Duration.display()

    "#{val}"
    |> append_tag(Map.get(datum, :tag))
  end

  # %{
  #   display: "rating",
  #   tag: "last 30 days",
  #   value: 3.9123,
  #   title: "Average Maintenance Rating"
  # %}
  #
  # Value is rating out of 5.0 or nil
  def format(%{display: "rating"} = datum) do
    val =
      (datum.value / 1)
      |> Float.round(1)

    "#{val}/5"
    |> append_tag(Map.get(datum, :tag))
  end

  # %{
  #   display: "percentage",
  #   value: 82.33333333,
  #   title: "Make Ready",
  # }
  #
  # Value is a percentage (presumably 0-100) or nil
  def format(%{display: "percentage", value: value} = datum) do
    # value can be any numeric (int or float) - doing / 1 converts to a float.
    # This is super hacky.
    rounded =
      (value / 1)
      |> Float.round(1)

    "#{rounded}%"
    |> append_tag(Map.get(datum, :tag))
  end

  # %{
  #   display: "number",
  #   title: "Open Work Orders",
  #   value: 17,
  # }
  #
  # Value is integer
  def format(%{display: "number"} = datum) do
    datum.value
    |> append_tag(Map.get(datum, :tag))
  end

  # Any unhandled cases - we want anything unhandled to fail pretty obviously,
  # assuming people are writing tests
  def format(_) do
    "N/A"
  end

  def append_tag(string, tag) do
    if blank?(tag) do
      "#{string}"
    else
      "#{string} (#{tag})"
    end
  end

  # checks if the string is either nil or blank (defined as an empty string or
  # string with spaces in it)
  defp blank?(str_or_nil) do
    "" == str_or_nil |> to_string() |> String.trim()
  end
end
