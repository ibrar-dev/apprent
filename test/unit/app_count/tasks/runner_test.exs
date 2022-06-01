defmodule AppCount.TaskRunnerTest do
  alias AppCount.Repo
  alias AppCount.Tasks
  alias AppCount.Jobs
  use AppCount.DataCase
  @moduletag :task_runner

  test "task runner works" do
    test_func = fn arg1, arg2, schema ->
      Tasks.Task.log("running with: #{inspect(arg1)} and #{inspect(arg2)} #{inspect(schema)}")
      result = arg1 + arg2
      Tasks.Task.log("result is: #{result}")
      result * 2
    end

    Tasks.Runner.run_task("Successful addition", test_func, [10, 14, "dasmen"], "dasmen")
    Tasks.Runner.run_task("Bad addition", test_func, [10, %{a: 1}, "dasmen"], "dasmen")
    Process.sleep(50)
    success = Repo.get_by(Jobs.Task, description: "Successful addition")
    assert success.success
    assert length(success.logs) == 2
    failure = Repo.get_by(Jobs.Task, description: "Bad addition")
    refute failure.success
    assert length(failure.logs) == 1
  end
end
