defmodule AppCount.Repo.Migrations.AddVisibleToMaintenanceNotes do
  use Ecto.Migration

  def change do
  	alter table(:maintenance__notes) do 
  		add :visible_to_resident, :boolean, default: false, null: false
  	end
  end
end
