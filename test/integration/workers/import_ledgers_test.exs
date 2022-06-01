defmodule AppCount.Workers.ImportLedgersTest do
  use AppCount.DataCase
  alias AppCount.Support.HTTPClient

  @get_resident_data File.read!(Path.expand("../resources/Yardi/get_resident_data.xml", __DIR__))

  setup do
    property = insert(:property, external_id: "2010", setting: nil)
    insert(:setting, property_id: property.id, sync_ledgers: true, integration: "Yardi")
    insert(:tenancy, unit: insert(:unit, property: property), external_id: "t0019240")

    insert(:processor,
      name: "Yardi",
      type: "management",
      keys: ["A", "B", "C", "D", "E", "F", "G", "H", "I"],
      property: property
    )

    params = %{
      function: "YardiImportLedgers",
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
    HTTPClient.initialize([@get_resident_data])

    AppCount.Jobs.Server.run_due_jobs(state, Timex.from_unix(ts))
    assert_receive {:DOWN, ^ref, :process, _, :killed}, 500
    desc = "Import tenant ledgers for Property: #{property.id}"

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
