defmodule AppCount.Repo.Migrations.SwitchAddressFieldsOnProspects do
  use Ecto.Migration

  def change do
    alter table(:prospects__prospects) do
      remove :address
      add :address, :jsonb, null: false, default: "{}"
    end
  end
end
