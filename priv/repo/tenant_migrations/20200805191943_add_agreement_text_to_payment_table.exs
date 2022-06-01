defmodule AppCount.Repo.Migrations.AddAgreementTextToPaymentTable do
  use Ecto.Migration

  def change do
    alter table("accounting__payments") do
      add :agreement_text, :text, default: "", null: true
    end
  end

end
