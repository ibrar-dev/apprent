defmodule AppCount.Jobs.Job do
  use Ecto.Schema
  import Ecto.Changeset

  schema "jobs__jobs" do
    field :arguments, AppCount.Jobs.ArgList
    field :function, :string
    field :last_run, :integer
    field :next_run, :integer
    embeds_one :schedule, AppCount.Jobs.Schedule, on_replace: :update

    timestamps()
  end

  @doc false

  def changeset(job, attrs) do
    job
    |> cast(attrs, [:function, :last_run, :next_run, :arguments])
    |> cast_schedule(attrs)
    |> validate_required([:schedule, :function, :arguments])
    |> check_constraint(:year, name: :year_invalid)
    |> check_constraint(:month, name: :month_invalid)
    |> check_constraint(:day, name: :day_invalid)
    |> check_constraint(:hour, name: :hour_invalid)
    |> check_constraint(:minute, name: :minute_invalid)
    |> check_constraint(:week, name: :week_invalid)
    |> check_constraint(:wday, name: :wday_invalid)
    |> check_constraint(:day, name: :day_conflict)
  end

  defp cast_schedule(cs, %{schedule: _}), do: cast_embed(cs, :schedule)
  defp cast_schedule(cs, %{"schedule" => _}), do: cast_embed(cs, :schedule)
  defp cast_schedule(cs, _), do: cs
end
