defmodule AppCount.Repo.Migrations.UniqueContraintForReportTemplates do
  use Ecto.Migration

  def change do
    create unique_index(:accounting__report_templates, [:name])
  end
end
