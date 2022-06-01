defmodule AppCount.Repo.Migrations.DeprecatePaymentSourceCryptedFields do
  use Ecto.Migration

  def change do
    # Deprecate old Num1 and Num2
    rename table("accounts__payment_sources"), :num1, to: :deprecated_num1
    rename table("accounts__payment_sources"), :num2, to: :deprecated_num2

    # Replace with new Num1 and Num2
    rename table("accounts__payment_sources"), :local_num1, to: :num1
    rename table("accounts__payment_sources"), :local_num2, to: :num2

    # Remove nil constraint until we drop the column so that we can still insert new records
    alter table("accounts__payment_sources") do
      modify :deprecated_num1, :text, null: true
      modify :deprecated_num2, :text, null: true
    end
  end
end
