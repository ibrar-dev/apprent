defmodule AppCount.Repo.Migrations.MakeTaskLogsIntoTextArray do
  use Ecto.Migration

  def change do
    alter table(:jobs__tasks) do
      modify :logs, {:array, :text}, null: false, default: "{}"
    end
  end
end
