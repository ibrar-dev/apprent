defmodule AppCount.Repo.Migrations.AddNSFFeeToPropertySettings do
  use Ecto.Migration

  def change do
    alter table(:properties__settings) do
      add :nsf_fee, :integer, null: false, default: 50
    end
  end
end
