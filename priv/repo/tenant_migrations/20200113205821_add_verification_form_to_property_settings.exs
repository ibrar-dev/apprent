defmodule AppCount.Repo.Migrations.AddVerificationFormToPropertySettings do
  use Ecto.Migration

  def change do
    alter table(:properties__settings) do
      add :verification_form, :text, null: false, default: ""
    end

    alter table(:admins__approvals) do
      add :amount, :decimal, null: true
    end
  end
end
