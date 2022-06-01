defmodule AppCount.Repo.Migrations.AddAttachmentToAlertAndActiveToPropertySetting do
  use Ecto.Migration

  def change do
    alter table(:properties__settings) do
      add :active, :boolean, default: true, null: false
    end
    alter table(:admins__alerts) do
      add :attachment_id, references(:data__uploads, on_delete: :nilify_all), null: true
    end
  end
end
