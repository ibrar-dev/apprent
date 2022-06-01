defmodule AppCount.Tasks.Workers.YardiImportLedgers do
  use AppCount.Tasks.Worker, "Import Ledgers from Yardi"

  @impl AppCount.Tasks.Worker
  def perform(schema \\ "dasmem") do
    AppCount.Yardi.perform_import_ledgers(schema)
  end
end
