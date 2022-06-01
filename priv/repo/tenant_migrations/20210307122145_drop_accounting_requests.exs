defmodule AppCount.Repo.Migrations.DropAccountingRequests do
  use Ecto.Migration

  def change do
    drop table(:accounting__requests)
  end
end
