defmodule AppCount.Repo.Migrations.AddMoveOutReasonToLeases do
  use Ecto.Migration

  def change do
    alter table(:properties__leases) do
      add :move_out_reason_id, references(:settings__move_out_reasons, on_delete: :nothing)
    end
  end
end
