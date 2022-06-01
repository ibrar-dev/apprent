defmodule AppCount.Repo.Migrations.AddDocumentToLeases do
  use Ecto.Migration

  def change do
    alter table(:properties__leases) do
      add :document, :string
    end
  end
end
