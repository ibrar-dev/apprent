defmodule AppCount.Repo.Migrations.ModifyPaymentSourceSchemaToAcceptTokenizationFields do
  use Ecto.Migration

  def change do
    alter table("accounts__payment_sources") do
      add :is_tokenized, :boolean, default: false
      add :last_4, :string, default: ""
    end
  end
end
