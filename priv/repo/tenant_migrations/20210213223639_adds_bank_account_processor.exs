defmodule AppCount.Repo.Migrations.AddsBankAccountProcessor do
  use Ecto.Migration

  def change do
   alter table("accounting__payment_sessions") do
      add :bank_account_processor_id, :integer
      add :credit_card_processor_id, :integer
    end
  end
end
