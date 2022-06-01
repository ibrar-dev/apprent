defmodule AppCount.Repo.Migrations.RenameSsnSwapForPerson do
  use Ecto.Migration

  def change do
    alter table("rent_apply__persons") do
      remove :ssn, :string, default: ""
    end

    rename table("rent_apply__persons"),  :local_ssn, to: :ssn
  end
end
