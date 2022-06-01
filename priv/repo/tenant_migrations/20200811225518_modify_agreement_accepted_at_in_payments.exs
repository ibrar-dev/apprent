defmodule AppCount.Repo.Migrations.ModifyAgreementAcceptedAtInPayments do
  use Ecto.Migration

  def change do
    alter table("accounting__payments") do
      remove :agreement_accepted_at
      add :agreement_accepted_at, :utc_datetime
    end
  end
end
