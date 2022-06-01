defmodule AppCount.Repo.Migrations.MoveToCitext do
  use Ecto.Migration

  def change do
    alter table(:accounts__accounts) do
      modify :username, :citext, null: false
    end

    alter table(:properties__tenants) do
      modify :email, :citext
    end

    alter table(:rent_apply__persons) do
      modify :email, :citext, null: false
    end

    alter table(:properties__persons) do
      modify :email, :citext
    end

    alter table(:prospects__prospects) do
      modify :email, :citext
    end

    alter table(:accounting__payees) do
      modify :email, :citext
    end

    alter table(:vendors__vendors) do
      modify :email, :citext
    end

    alter table(:maintenance__techs) do
      modify :email, :citext, null: false
    end

    alter table(:rent_apply__saved_forms) do
      modify :email, :citext, null: false
    end
  end
end
