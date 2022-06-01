defmodule AppCount.EctoTypes.Month do
  use Ecto.Type
  @format "{Mfull} {YYYY}"

  def type, do: :date

  def cast(date), do: {:ok, date}

  def load(date) do
    {:ok, Timex.format!(date, @format)}
  end

  def dump(date) when is_binary(date) do
    {:ok, Timex.parse!(date, @format) |> Timex.to_date()}
  end

  def dump(date) do
    {:ok, date}
  end
end
