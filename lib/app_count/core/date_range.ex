defmodule AppCount.Core.DateRange do
  @moduledoc false
  alias AppCount.Core.DateRange

  defstruct from: :not_set, to: :not_set

  def new(%Date{} = from, %Date{} = to) do
    %DateRange{from: from, to: to}
  end

  def to_range(%DateRange{from: from, to: to}) do
    %Date.Range{first: from, last: to}
  end
end
