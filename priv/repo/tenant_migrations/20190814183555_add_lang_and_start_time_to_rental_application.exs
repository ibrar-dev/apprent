defmodule AppCount.Repo.Migrations.AddLangAndStartTimeToRentalApplication do
  use Ecto.Migration

  def change do
    alter table(:rent_apply__rent_applications) do
      add :lang, :string, null: true
      add :start_time, :integer, null: true
    end
  end
end
