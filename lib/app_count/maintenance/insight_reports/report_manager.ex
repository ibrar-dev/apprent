defmodule AppCount.Maintenance.InsightReports.ReportManager do
  alias AppCount.Maintenance.InsightReports.Reports
  use GenServer

  # PUBLIC INTERFACE --------------------------
  def make_and_send(property_id, report_type) do
    GenServer.cast(__MODULE__, {:process_report, property_id, report_type})
  end

  # BOOT CONCERNS ----------------------------

  def init(_) do
    {:ok, %{}, {:continue, :schedule_next_process}}
  end

  def start_link(_opts \\ []) do
    AppCount.GenserverLogger.starting(__MODULE__)
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  # SERVER INTERFACE ----------------------------

  def handle_cast({:process_report, property_id, report_type}, state) do
    Reports.make_and_send(property_id, report_type)
    {:noreply, state}
  end

  # Kick off report generation, then re-queue for an hour from now
  def handle_info(:generate_daily_reports, state) do
    Reports.make_and_send("daily")
    {:noreply, state, {:continue, :schedule_next_process}}
  end

  # We run this process on the hour every hour
  def handle_continue(:schedule_next_process, state) do
    interval =
      Timex.now()
      |> next_run_in_ms_away()

    Process.send_after(self(), :generate_daily_reports, interval)

    {:noreply, state}
  end

  # Given some DateTime, shift 1 hour into the future (on the hour exactly) and
  # return the number of milliseconds between now and then.
  def next_run_in_ms_away(now) do
    now
    |> Timex.shift(hours: 1)
    |> Timex.set(minute: 0, second: 0)
    |> Timex.diff(now, :milliseconds)
  end
end
