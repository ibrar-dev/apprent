defmodule AppCount.Repo.Migrations.DeprecateSsnInScreenings do
  use Ecto.Migration

  def change do
    rename table("leases__screenings"), :ssn, to: :deprecated_ssn
    rename table("leases__screenings"), :local_ssn, to: :ssn

    alter table("leases__screenings") do
      modify :deprecated_ssn, :text, null: true
    end
  end
end
