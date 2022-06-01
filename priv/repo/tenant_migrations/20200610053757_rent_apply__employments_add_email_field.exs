defmodule AppCount.Repo.Migrations.RentApplyEmploymentsAddEmailField do
  use Ecto.Migration

  def change do
    alter table("rent_apply__employments") do
      add :email, :citext, null: true
    end
  end
end
