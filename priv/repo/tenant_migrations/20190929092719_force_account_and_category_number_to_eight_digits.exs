defmodule AppCount.Repo.Migrations.ForceAccountAndCategoryNumberToEightDigits do
  use Ecto.Migration

  def change do
    create constraint(:accounting__categories, :valid_number, check: "num >= 10000000 AND num <= 99999999")
    create constraint(:accounting__accounts, :valid_number, check: "num >= 10000000 AND num <= 99999999")
  end
end
