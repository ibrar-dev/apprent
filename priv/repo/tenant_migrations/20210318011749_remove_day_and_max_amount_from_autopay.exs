defmodule AppCount.Repo.Migrations.RemoveDayAndMaxAmountFromAutopay do
  use Ecto.Migration

  def change do
    alter table(:accounts__autopays) do
      remove :day, :integer
      remove :max_amount, :integer
    end
  end
end
