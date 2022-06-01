defmodule AppCount.Repo.Migrations.AddPayerFieldsToPayments do
  use Ecto.Migration

  def change do
    alter table("accounting__payments") do
      add :last_4, :string, default: "", nil: true
      add :payer_name, :string, default: "", nil: true
      add :payment_type, :string, default: "", nil: true
    end
  end
end
