defmodule AppCount.Repo.Migrations.AddLocalFieldsToPaymentSources do
  use Ecto.Migration

  def change do
    alter table("accounts__payment_sources") do
      add :local_num1, :text, default: ""
      add :local_num2, :text, default: ""
    end
  end
end
