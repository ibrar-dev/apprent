defmodule AppCount.Repo.Migrations.RemoveNullConstraintFromHistoriesResidencyLength do
  use Ecto.Migration

  def change do
    alter table(:rent_apply__histories) do
      modify :residency_length, :string, null: true
    end
  end
end
