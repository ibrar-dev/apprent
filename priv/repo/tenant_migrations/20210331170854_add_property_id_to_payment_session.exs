defmodule AppCount.Repo.Migrations.AddPropertyIdToPaymentSession do
  use Ecto.Migration

  def change do
    alter table("accounting__payment_sessions") do
      add :property_id, :integer,
      null: true, 
      default: nil
    end

  end
end
