defmodule AppCount.Repo.Migrations.DropRentApplyScreenings do
  use Ecto.Migration

  def change do
    drop table(:rent_apply__screenings)
  end
end
