defmodule AppCount.Repo.Migrations.AddChargeCodesToAccount do
  use Ecto.Migration

  def change do
    alter table(:accounting__accounts) do
      add :charge_code, :string
    end

    create unique_index(:accounting__accounts, [:charge_code])
  end
end
