defmodule AppCount.Maintenance.Job do
  use Ecto.Schema
  import Ecto.Changeset
  alias AppCount.Maintenance.Job

  schema "maintenance__jobs" do
    belongs_to :property, AppCount.Properties.Property
    belongs_to :tech, AppCount.Maintenance.Tech

    timestamps()
  end

  @doc false
  def changeset(%Job{} = job, attrs) do
    job
    |> cast(attrs, [:property_id, :tech_id])
    |> validate_required([:property_id, :tech_id])
    |> unique_constraint(:unique, name: :maintenance__jobs_property_id_tech_id_index)
  end
end
