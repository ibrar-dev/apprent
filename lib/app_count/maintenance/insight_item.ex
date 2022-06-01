defmodule AppCount.Maintenance.InsightItem do
  defstruct comments: [],
            reading: %AppCount.Maintenance.Reading{},
            meta: %{mood: :neutral, reporter: "NoReporter"}

  def new do
    %__MODULE__{}
  end
end
