defmodule AppCount.Repo.Migrations.DropChargeTypeRef do
  use Ecto.Migration

  def change do
    alter table(:properties__charges) do
      remove :charge_type_id
    end
  end
end
