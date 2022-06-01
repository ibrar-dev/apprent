defmodule AppCount.Repo.Migrations.AddLocalSsnToRentApplyPerson do
  use Ecto.Migration

  def change do
    alter table("rent_apply__persons") do
      add :local_ssn, :string, default: ""
    end
  end
end
