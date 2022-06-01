defmodule AppCount.Repo.Migrations.ModifyAutopayAmountToDecimal do
  use Ecto.Migration

  def change do
    alter table("accounts__autopays") do
      remove :max_amount
      add :max_amount, :decimal
    end
  end
end
