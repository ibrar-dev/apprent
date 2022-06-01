defmodule AppCount.Repo.Migrations.AddSocialToProperties do
  use Ecto.Migration

  def change do
    alter table(:properties__properties) do
      add :social, :jsonb, null: false, default: "{}"
    end
  end
end
