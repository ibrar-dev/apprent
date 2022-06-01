defmodule AppCount.Repo.Migrations.AddAdminToChargesAndPayments do
  use Ecto.Migration

  def change do
    alter table(:accounting__payments) do
      add :admin, :string
    end
    alter table(:accounting__charges) do
      add :admin, :string
    end
  end
end
