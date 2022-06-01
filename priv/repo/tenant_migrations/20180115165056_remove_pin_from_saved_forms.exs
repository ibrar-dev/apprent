defmodule AppCount.Repo.Migrations.RemovePinFromSavedForms do
  use Ecto.Migration

  def change do
    alter table(:rent_apply__saved_forms) do
      remove :pin
    end
  end
end
