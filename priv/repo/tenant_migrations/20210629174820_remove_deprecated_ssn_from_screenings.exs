defmodule AppCount.Repo.Migrations.RemoveDeprecatedSsnFromScreenings do
  use Ecto.Migration

  def change do
    alter table("leases__screenings") do
      remove :deprecated_ssn, :text
    end
  end
end
