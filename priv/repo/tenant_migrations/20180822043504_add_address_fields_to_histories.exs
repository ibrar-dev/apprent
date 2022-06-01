defmodule AppCount.Repo.Migrations.AddAddressFieldsToHistories do
  use Ecto.Migration

  def change do
    alter table(:rent_apply__histories) do
      add :street, :string
      add :unit, :string
      add :city, :string
      add :state, :string
      add :zip, :string
    end
  end
end
