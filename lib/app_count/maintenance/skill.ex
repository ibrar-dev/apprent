defmodule AppCount.Maintenance.Skill do
  use Ecto.Schema
  import Ecto.Changeset
  alias AppCount.Maintenance.Skill

  schema "maintenance__skills" do
    belongs_to :tech, AppCount.Maintenance.Tech
    belongs_to :category, AppCount.Maintenance.Category

    timestamps()
  end

  @doc false
  def changeset(%Skill{} = skill, attrs) do
    skill
    |> cast(attrs, [:tech_id, :category_id])
    |> validate_required([:tech_id, :category_id])
    |> unique_constraint(:tech_id_category_id)
  end
end
