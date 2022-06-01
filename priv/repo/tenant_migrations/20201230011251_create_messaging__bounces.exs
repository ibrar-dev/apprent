defmodule AppCount.Repo.Migrations.CreateMessagingBounces do
  use Ecto.Migration

  def change do
    create table(:messaging__bounces) do
      add :target, :string, null: false
      
      timestamps()
    end

  end
end
