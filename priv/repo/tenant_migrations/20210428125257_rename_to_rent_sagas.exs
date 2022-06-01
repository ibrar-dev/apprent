defmodule AppCount.Repo.Migrations.RenameToRentSagas do
  use Ecto.Migration

  def change do
    rename table(:accounting__payment_sessions),  to: table(:finance__rent_sagas)
  end
end
