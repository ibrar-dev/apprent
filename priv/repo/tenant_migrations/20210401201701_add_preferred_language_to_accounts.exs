defmodule AppCount.Repo.Migrations.AddPreferredLanguageToAccounts do
  use Ecto.Migration

  def change do
    alter table("accounts__accounts") do
      add :preferred_language, :string, default: "english"
    end
  end
end
