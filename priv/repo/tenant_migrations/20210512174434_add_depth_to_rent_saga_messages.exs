defmodule AppCount.Repo.Migrations.AddDepthToRentSagaMessages do
  use Ecto.Migration

  def change do
    alter table("finance__rent_sagas") do
      modify :message, :text
    end
  end
end
