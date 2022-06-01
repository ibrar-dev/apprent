defmodule AppCount.Repo.Migrations.AddRenewalRefToLeases do
  use Ecto.Migration

  def change do
    alter table(:properties__leases) do
      add :renewal_id, references(:properties__leases, on_delete: :nilify_all)
    end
  end
end
