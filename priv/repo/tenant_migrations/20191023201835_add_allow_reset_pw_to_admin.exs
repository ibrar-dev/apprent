defmodule AppCount.Repo.Migrations.AddAllowResetPWToAdmin do
  use Ecto.Migration

  def change do
    alter table(:admins__admins) do
      add :reset_pw, :boolean, null: false, default: true
    end
  end
end
