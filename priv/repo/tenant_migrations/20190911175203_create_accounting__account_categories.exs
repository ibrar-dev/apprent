defmodule AppCount.Repo.Migrations.CreateAccountingAccountCategories do
  use Ecto.Migration

  def change do
    create table(:accounting__account_categories) do
      add :name, :string, null: false
      add :path, {:array, :integer}, null: false, default: "{}"
      add :min, :integer, null: true
      add :max, :integer, null: true

      timestamps()
    end

  end
end
