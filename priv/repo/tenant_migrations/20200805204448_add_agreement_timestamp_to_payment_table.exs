defmodule AppCount.Repo.Migrations.AddAgreementTimestampToPaymentTable do
  use Ecto.Migration

  def change do
    alter table("accounting__payments") do
      add :agreement_accepted_at, :string, default: "", null: true
    end
  end
end
