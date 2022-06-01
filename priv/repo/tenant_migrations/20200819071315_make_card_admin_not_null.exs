defmodule AppCount.Repo.Migrations.MakeCardAdminNotNull do
  use Ecto.Migration

  def change do
    alter table(:maintenance__cards) do
      modify :admin, :string, null: false
    end
  end
end
