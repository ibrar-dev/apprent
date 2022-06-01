defmodule AppCount.Repo.Migrations.AddStashedParamsToApplications do
  use Ecto.Migration

  def change do
    alter table(:rent_apply__rent_applications) do
      add :approval_params, :jsonb, null: false, default: "{}"
    end
  end
end
