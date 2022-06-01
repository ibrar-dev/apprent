defmodule AppCount.Repo.Migrations.AddCurrentToEmployments do
  use Ecto.Migration

  def change do
    alter table(:rent_apply__employments) do
      add :current, :boolean, default: true, null: false
    end

    alter table(:rent_apply__histories) do
      add :current, :boolean, default: false, null: false
    end
  end
end
