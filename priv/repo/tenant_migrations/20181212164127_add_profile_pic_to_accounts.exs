defmodule AppCount.Repo.Migrations.AddProfilePicToAccounts do
  use Ecto.Migration

  def change do
    alter table(:accounts__accounts) do
      add :profile_pic, :string
    end
  end
end
