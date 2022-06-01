defmodule AppCount.Repo.Migrations.AddZipAndCvvConfirmedAtToPayments do
  use Ecto.Migration

  def change do
    alter table("accounting__payments") do
      add :zip_code_confirmed_at, :utc_datetime, nil: true
      add :cvv_confirmed_at, :utc_datetime, nil: true
    end
  end
end
