defmodule AppCount.Jobs.Server do
  use GenServer
  import AppCount.Jobs, only: [list_pending_jobs: 0, schedule_all: 0]
  alias AppCount.Jobs.Runner
  @process_name :jobs_server

  def refresh() do
    GenServer.cast(@process_name, :refresh)
  end

  def list do
    GenServer.call(@process_name, :list)
  end

  def run_due_jobs(jobs, now \\ Timex.now()) do
    current_ts =
      now
      |> Timex.to_unix()

    Enum.each(
      jobs,
      fn {ts, job_id, schema} ->
        if current_ts >= ts do
          Runner.run(job_id, schema)
        end
      end
    )
  end

  ## GenServer callbacks

  def start_link(_opts \\ []) do
    AppCount.GenserverLogger.starting(__MODULE__)
    GenServer.start_link(__MODULE__, [], name: @process_name)
  end

  def init(state) do
    Process.send_after(@process_name, :init, 30_000)
    {:ok, state}
  end

  def handle_cast(:refresh, _state) do
    {:noreply, list_pending_jobs()}
  end

  def handle_call(:list, _, state) do
    {:reply, state, state}
  end

  def handle_info(:init, state) do
    run_due_jobs(state)
    schedule_all()
    # Start timer at the top of the minute
    Timex.now()
    |> Timex.shift(minutes: 1)
    |> Map.merge(%{second: 0, microsecond: {0, 0}})
    |> Time.diff(Timex.now(), :millisecond)
    |> set_run_timer()

    handle_cast(:refresh, state)
  end

  def handle_info(:run, state) do
    run_due_jobs(state)
    set_run_timer()
    {:noreply, state}
  end

  # Needed for some weird Postgrex callback
  def handle_info(_, state), do: {:noreply, state}

  defp set_run_timer(time \\ 60_000) do
    Process.send_after(@process_name, :run, time)
  end
end
