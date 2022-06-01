defmodule AppCount.Repo.Migrations.AddEmailToRentHistories do
  use Ecto.Migration

  def change do
    alter table(:rent_apply__histories) do
      add :landlord_email, :string
    end
  end
end
