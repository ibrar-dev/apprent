defmodule AppCount.Repo.Migrations.AddLocalSsnToScreening do
  use Ecto.Migration

  def change do
    alter table("leases__screenings") do
      add :local_ssn, :string, default: ""
    end
  end
end
