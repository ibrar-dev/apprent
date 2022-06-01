defmodule AppCount.Repo.Migrations.AddTermsToProperties do
  use Ecto.Migration

  def change do
    alter table(:properties__properties) do
      add :terms, :text, null: false, default: ""
    end
  end
end
