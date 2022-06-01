defmodule AppCount.Repo.Migrations.AddSubtypeToPaymentSources do
  use Ecto.Migration

  def change do
    alter table("accounts__payment_sources") do
      add :subtype, :string, default: ""
    end
  end
end
