defmodule AppCount.Repo.Migrations.MakePaymentPropertyIdRequired do
  use Ecto.Migration

  def change do
    alter table(:accounting__payments) do
      modify :property_id, :bigint, null: false
    end
  end
end
