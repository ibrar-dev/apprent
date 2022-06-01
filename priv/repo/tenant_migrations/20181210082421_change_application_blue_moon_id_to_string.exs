defmodule AppCount.Repo.Migrations.ChangeApplicationBlueMoonIdToString do
  use Ecto.Migration

  def change do
    alter table(:rent_apply__rent_applications) do
      modify :bluemoon_lease_id, :string
    end
  end
end
