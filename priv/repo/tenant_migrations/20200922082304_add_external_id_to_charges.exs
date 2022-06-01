defmodule AppCount.Repo.Migrations.AddExternalIdToCharges do
  use Ecto.Migration

  def change do
    alter table(:accounting__charges) do
      add :external_id, :string
    end

    create unique_index(:accounting__charges, [:external_id])
  end
end
