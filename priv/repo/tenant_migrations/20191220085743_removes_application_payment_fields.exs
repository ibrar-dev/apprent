defmodule AppCount.Repo.Migrations.RemovesApplicationPaymentFields do
  use Ecto.Migration

  def change do
    alter table(:rent_apply__rent_applications) do
      remove :payment_id
      remove :admin_payment_id
    end
  end
end
