defmodule AppCount.Jobs.ServerTest do
  use AppCount.DataCase

  setup do
    start_time = AppCount.current_time()

    target_hour =
      start_time
      |> Timex.shift(hours: 2)
      |> Map.get(:hour)

    job_params = %{
      schedule: %{
        hour: [target_hour]
      },
      function: "FakeTask",
      arguments: []
    }

    {:ok, job} = AppCount.Jobs.Utils.Jobs.create_job(job_params, "dasmen")
    {:ok, job: job, start_time: start_time}
  end

  test "server refresh and server list", %{job: job, start_time: start_time} do
    target_ts =
      Timex.shift(start_time, hours: 2)
      |> Map.merge(%{minute: 0, second: 0})
      |> Timex.to_unix()

    [{ts, job_id, "dasmen"}] = AppCount.Jobs.Server.list()
    assert ts == target_ts
    assert job_id == job.id
  end

  test "run_due_jobs" do
    ref = AppCount.Support.FakeQueue.monitor_queue()
    [{ts, _job_id, "dasmen"}] = state = AppCount.Jobs.Server.list()
    AppCount.Jobs.Server.run_due_jobs(state, Timex.from_unix(ts))
    assert_receive {:DOWN, ^ref, :process, _, :killed}, 500
  end
end
