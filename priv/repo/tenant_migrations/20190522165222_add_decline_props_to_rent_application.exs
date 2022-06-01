defmodule AppCount.Repo.Migrations.AddDeclinePropsToRentApplication do
  use Ecto.Migration

  def change do
    alter table(:rent_apply__rent_applications) do
      add :declined_on, :date, null: true
      add :declined_reason, :string, null: true
      add :declined_by, :string, null: true
    end
  end
end
