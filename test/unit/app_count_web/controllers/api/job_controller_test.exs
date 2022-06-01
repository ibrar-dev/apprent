defmodule AppCount.Controllers.API.JobControllerTest do
  use AppCount.DataCase
  import AppCount, only: [current_time: 0]

  setup do
    start_schedule =
      current_time()
      |> Timex.shift(minutes: 2)

    job_params = %{
      schedule: %{},
      function: "FakeTask",
      arguments: []
    }

    %{schedule: Map.take(start_schedule, [:year, :month, :day, :hour, :minute])}
    |> Map.merge(job_params)

    ~M[job_params]
  end

  test "Create job, with fake params in test schema", ~M[job_params] do
    AppCount.Jobs.Utils.Jobs.create_job(job_params, "test")

    ref = AppCount.Support.FakeQueue.monitor_queue()
    [{ts, _job_id, _schema}] = state = AppCount.Jobs.Server.list()
    AppCount.Jobs.Server.run_due_jobs(state, Timex.from_unix(ts))

    assert_receive {:DOWN, ^ref, :process, _, :killed}, 500
  end

  test "Create job, with fake params in maintenance schema", ~M[job_params] do
    AppCount.Jobs.Utils.Jobs.create_job(job_params, "maintenance")

    ref = AppCount.Support.FakeQueue.monitor_queue()
    [{ts, _job_id, _schema}] = state = AppCount.Jobs.Server.list()
    AppCount.Jobs.Server.run_due_jobs(state, Timex.from_unix(ts))

    assert_receive {:DOWN, ^ref, :process, _, :killed}, 500
  end

  test "Create job, with fake params in dasmen schema", ~M[job_params] do
    AppCount.Jobs.Utils.Jobs.create_job(job_params, "dasmen")

    ref = AppCount.Support.FakeQueue.monitor_queue()
    [{ts, _job_id, _schema}] = state = AppCount.Jobs.Server.list()
    AppCount.Jobs.Server.run_due_jobs(state, Timex.from_unix(ts))

    assert_receive {:DOWN, ^ref, :process, _, :killed}, 500
  end
end
