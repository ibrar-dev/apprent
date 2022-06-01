defmodule AppCount.Repo.Migrations.AddRentalApplicationTermsAndConditionsToPayments do
  use Ecto.Migration

  def change do
    alter table("ledgers__payments") do
      add :rent_application_terms_and_conditions, :text, default: ""
    end
  end
end
