defmodule AppCount.Repo.Migrations.AddAccountIdToDamages do
  use Ecto.Migration

  def change do
    alter table(:settings__damages) do
      add :account_id, references(:accounting__accounts, on_delete: :delete_all), null: false
    end
  end
end
