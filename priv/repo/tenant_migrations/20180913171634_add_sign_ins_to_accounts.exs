defmodule AppCount.Repo.Migrations.AddSignInsToAccounts do
  use Ecto.Migration

  def change do
    alter table(:accounts__accounts) do
      add :last_sign_in, :naive_datetime
      add :receives_mailings, :boolean, default: true, null: false
      add :autopay, :boolean, default: false, null: false
    end
  end
end
