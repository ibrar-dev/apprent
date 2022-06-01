defmodule AppCount.Repo.Migrations.ChangeChargeFields do
  use Ecto.Migration

  def change do
    alter table(:accounting__charges) do
      add :charge_id, references(:properties__charges, on_delete: :nilify_all)
      remove :charge_type_id
    end

    create index(:accounting__charges, [:charge_id])
  end
end
