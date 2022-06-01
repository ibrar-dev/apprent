defmodule AppCount.Repo.Migrations.RemoveDeprecatedPaymentSourceFields do
  use Ecto.Migration

  def change do
    alter table("accounts__payment_sources") do
       remove :deprecated_num1, :text
       remove :deprecated_num2, :text
    end
  end
end
