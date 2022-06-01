defmodule AppCount.Repo.Migrations.DropLastSignInField do
  use Ecto.Migration

  def change do
    alter table(:accounts__accounts) do
      remove :last_sign_in
    end
  end
end
