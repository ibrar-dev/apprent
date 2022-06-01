defmodule AppCount.Repo.Migrations.AddPayerIpAddressToPayments do
  use Ecto.Migration

  def change do
    alter table("accounting__payments") do
      add :payer_ip_address, :string, default: "", null: true
    end
  end
end
