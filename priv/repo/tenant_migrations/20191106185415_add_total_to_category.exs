defmodule AppCount.Repo.Migrations.AddTotalToCategory do
  use Ecto.Migration

  def change do
    alter table(:accounting__categories) do
      add :max, :integer, null: true
    end

    create constraint(:accounting__categories, :valid_max_number, check: "max >= 10000000 AND max <= 99999999")
  end
end
