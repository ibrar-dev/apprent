defmodule AppCount.Workers.ImportResidentsTest do
  use AppCount.DataCase
  alias AppCount.Support.HTTPClient

  @import_residents File.read!(
                      Path.expand(
                        "../resources/Yardi/import_residents.xml",
                        __DIR__
                      )
                    )

  @get_tenants File.read!(
                 Path.expand(
                   "../resources/Yardi/get_tenants.xml",
                   __DIR__
                 )
               )

  setup do
    property = insert(:property, external_id: "2010", setting: nil)
    insert(:setting, property_id: property.id, sync_residents: true, integration: "Yardi")

    insert(:processor,
      name: "Yardi",
      type: "management",
      keys: ["A", "B", "C", "D", "E", "F", "G", "H", "I"],
      property: property
    )

    params = %{
      function: "YardiImportResidents",
      schedule: %{},
      next_run: Timex.to_unix(Timex.now()) + 100,
      arguments: []
    }

    %AppCount.Jobs.Job{}
    |> AppCount.Jobs.Job.changeset(params)
    |> Repo.insert!()

    AppCount.Jobs.Server.refresh()
    {:ok, property: property}
  end

  test "import residents task runs", %{property: property} do
    ref = AppCount.Support.SynchronousQueue.monitor_queue()
    [{ts, _job_id, "dasmen"}] = state = AppCount.Jobs.Server.list()
    HTTPClient.initialize([@import_residents, @get_tenants])

    AppCount.Jobs.Server.run_due_jobs(state, Timex.from_unix(ts))
    assert_receive {:DOWN, ^ref, :process, _, :killed}, 500
    desc = "Import residents property ID: #{property.id}"

    task =
      Repo.get_by(
        AppCount.Jobs.Task,
        [description: desc],
        prefix: "dasmen"
      )

    assert task
    assert task.error == nil
    HTTPClient.stop()
  end
end
