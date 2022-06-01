defmodule AppCount.Repo.Migrations.ContactFieldsForPayees do
  use Ecto.Migration

  def change do
    alter table(:accounting__payees) do
      add :street, :string
      add :city, :string
      add :zip, :string
      add :state, :string
      add :email, :string
      add :phone, :string
      remove :address
    end
  end
end
