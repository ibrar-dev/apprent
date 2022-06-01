defmodule AppCount.Jobs.RunnerTest do
  use AppCount.Case

  test "runs jobs passed to it" do
    ref = AppCount.Support.FakeQueue.monitor_queue()

    %AppCount.Jobs.Job{function: "Charges", arguments: []}
    |> AppCount.Jobs.Runner.do_run("")

    assert_receive {:DOWN, ^ref, :process, _, :killed}, 500
  end
end
