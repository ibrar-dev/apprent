defmodule AppCount.Repo.Migrations.CreatePushToken do
  use Ecto.Migration

  def change do
    alter table(:accounts__accounts) do
        add :push_token, :string
     end
  end
end
