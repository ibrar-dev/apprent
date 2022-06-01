defmodule AppCount.Repo.Migrations.AddPaymentTermsToAutopay do
  use Ecto.Migration

  def change do
    alter table("accounts__autopays") do
      add :payer_ip_address, :string, default: ""
      add :agreement_text, :text, default: ""
      add :agreement_accepted_at, :utc_datetime
    end
  end
end
