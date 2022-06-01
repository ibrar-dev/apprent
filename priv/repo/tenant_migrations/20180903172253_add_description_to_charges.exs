defmodule AppCount.Repo.Migrations.AddDescriptionToCharges do
  use Ecto.Migration

  def change do
    alter table(:accounting__charges) do
      add :description, :text, default: "", null: false
    end
  end
end
