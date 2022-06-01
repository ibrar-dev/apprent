defmodule AppCount.Maintenance.InsightReports.PerformancePoints do
  @doc """
  Takes in work order saturation (percent) and reports a sub-grade
  The saturation is scaled by a factor of 1.5 and then subtracted from the weight (25)
  Bottoms out at 0 points

  Scaling factor: 1.5
  """
  def work_order_saturation({saturation, :percent}) do
    # =(MAX((25 - 1.5*(K28*100)), 0))"
    max(25 - 1.5 * (saturation * 100), 0)
  end

  @doc """
  Gives a sub-grade worth 7.5 if the property has no callbacks, otherwise gives 0 points.
  """
  def callbacks({0, :count}) do
    7.5
  end

  def callbacks({_not_zero, :count}) do
    0
  end

  @doc """
  Gives a sub-grade worth 7.5 if the property has no violations, otherwise gives 0 points.
  """
  def violations({0, :count}) do
    7.5
  end

  def violations({_not_zero, :count}) do
    0
  end

  @doc """
  Gives the average rating as the sub-grade

  TODO: Change the ratings grader to more accurately report the ratings. Perhaps by
  taking the past two weeks worth of ratings?
  """
  def ratings({rating, :rating}) do
    rating
  end

  @doc """
  The average duration for open work orders is graded as a step-function:
    < 1 day: 15 points (maximum points)
    < 2 days: 12 points
    < 3 days: 10 points
    < 4 days: 5 points
    < 5 days: 2 points
    >= 5days: 0 points

    TODO: Make into a linear function? Or if we keep the step function, make it so that
    the points given are a fraction of the weight (a constant) so that adjusting the weight
    is easier
  """
  def work_order_turnaround({days, :days}) do
    cond do
      days < 1 ->
        15

      days < 2 ->
        12

      days < 3 ->
        10

      days < 4 ->
        5

      days < 5 ->
        2

      days >= 5 ->
        0

      true ->
        0
    end
  end

  @doc """
  Make Ready Turnaround Time is graded as a step function with a linear function
  for anything above 5 days. The function grades more harshly above 8 days.
  """
  def make_ready_turnaround({turnaround_days, :days}) do
    cond do
      turnaround_days == 0 ->
        0

      turnaround_days <= 5 ->
        15

      turnaround_days <= 8 ->
        20 - turnaround_days

      turnaround_days > 8 ->
        max(-2 * turnaround_days + 28, 0)

      # Question for Eric: What do we expect will trigger this case ?
      true ->
        0
    end
  end

  @doc """
  Make Ready % is graded as a linear function between 50% and 80%. Bottoms out at 0 below 50%
  and tops out at 15 above 80%
  """
  def make_ready_percent({percent, :percent}) do
    cond do
      percent < 50 ->
        0.0

      percent < 80 ->
        50.0 * (percent / 100.0) - 25.0

      percent >= 80 ->
        15.0
    end
    |> Float.round(1)
  end

  @doc """
  Make Ready Utilization Percentage is graded as a percentage of the weight.
  """
  def make_ready_utilization({value, :percent}) do
    value / 100 * 15
  end
end
