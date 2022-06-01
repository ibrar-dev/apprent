defmodule AppCount.Repo.Migrations.AddBannerToProperty do
  use Ecto.Migration

  def change do
    alter table(:properties__properties) do
      add :banner, :string
    end
  end
end
