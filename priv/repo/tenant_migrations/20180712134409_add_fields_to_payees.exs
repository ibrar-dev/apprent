defmodule AppCount.Repo.Migrations.AddFieldsToPayees do
  use Ecto.Migration

  def change do
    alter table(:accounting__payees) do
      add :tax_form, :string
      add :tax_id, :string
    end
  end
end
