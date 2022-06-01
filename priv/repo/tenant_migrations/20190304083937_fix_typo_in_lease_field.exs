defmodule AppCount.Repo.Migrations.FixTypoInLeaseField do
  use Ecto.Migration

  def change do
    rename table(:rent_apply__leases), :bug_infestaion, to: :bug_infestation
  end
end
