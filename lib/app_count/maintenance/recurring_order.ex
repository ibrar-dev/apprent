defmodule AppCount.Maintenance.RecurringOrder do
  use Ecto.Schema
  import Ecto.Changeset

  schema "maintenance__recurring_orders" do
    field :name, :string
    field :last_run, :integer
    field :next_run, :integer
    field :params, :map
    embeds_one :schedule, AppCount.Jobs.Schedule, on_replace: :update
    belongs_to :property, Module.concat(["AppCount.Properties.Property"])
    belongs_to :admin, Module.concat(["AppCount.Admins.Admin"])

    timestamps()
  end

  @doc false
  def changeset(recurring_order, attrs) do
    recurring_order
    |> cast(attrs, [:params, :name, :property_id, :next_run, :last_run, :admin_id])
    |> cast_schedule(attrs)
    |> validate_required([:schedule, :params, :name, :property_id])
  end

  defp cast_schedule(cs, %{schedule: _}), do: cast_embed(cs, :schedule)
  defp cast_schedule(cs, %{"schedule" => _}), do: cast_embed(cs, :schedule)
  defp cast_schedule(%{data: %{schedule: s}} = cs, _) when not is_nil(s), do: cs
end
