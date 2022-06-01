defmodule AppCount.Repo.Migrations.ChangeSomeForeignKeyConstraints do
  use Ecto.Migration

  def change do
    drop_if_exists constraint(:accounting__charges, "accounting__charges_type_id_fkey")
    drop_if_exists constraint(:accounting__charges, "accounting__charges_account_id_fkey")
    alter table(:accounting__charges) do
      modify :account_id, references(:accounting__accounts, on_delete: :nothing)
    end

    drop_if_exists constraint(:properties__charges, "properties__charges_type_id_fkey")
    alter table(:properties__charges) do
      modify :account_id, references(:accounting__accounts, on_delete: :nothing)
    end
  end
end
