defmodule AppCount.Repo.Migrations.AddImageToResidentEvent do
  use Ecto.Migration

  def change do
    alter table(:properties__resident_events) do
      add :image, :string
    end
  end
end
