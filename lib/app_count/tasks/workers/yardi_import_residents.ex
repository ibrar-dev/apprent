defmodule AppCount.Tasks.Workers.YardiImportResidents do
  use AppCount.Tasks.Worker, "Import Residents from Yardi"

  @impl AppCount.Tasks.Worker
  def perform(schema \\ "dasmen") do
    AppCount.Yardi.perform_import_residents(schema)
  end
end
