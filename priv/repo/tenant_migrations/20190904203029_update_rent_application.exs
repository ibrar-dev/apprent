defmodule AppCount.Repo.Migrations.UpdateRentApplication do
  use Ecto.Migration

  def change do
    alter table(:rent_apply__rent_applications) do
      add :security_deposit_id, references(:accounting__payments, on_delete: :nilify_all)
    end
  end
end
