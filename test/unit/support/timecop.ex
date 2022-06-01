defmodule AppCount.TimeCop do
  @moduledoc """
  The problem with this appraoh is that it prevent async testing
  and concurrent processing.
  Both of those are actually a benefit of Elixir.
  This approach goes against the sprit of Elixir concurrancy.
  Instead, lets start converting these tests and production code to eliminate side-effects.
  Or do simeple injects of DateTime.
  That way this kind of global manipulation will no longer be needed.
  """
  defmacro freeze(time, do: block) do
    quote do
      Agent.update(:timecop, fn _ -> convert(unquote(time)) end)
      result = unquote(block)
      Agent.update(:timecop, fn _ -> nil end)
      result
    end
  end

  def convert(%Date{} = d) do
    Timex.to_datetime(d, Timex.local().time_zone)
  end

  def convert(d), do: d
end
