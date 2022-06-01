defmodule AppCount.Tasks.QueueTest do
  use AppCount.DataCase
  alias AppCount.Tasks.Queue
  alias AppCount.Jobs.Task
  #
  alias AppCount.Repo
  @moduletag :tasks_queue
  @agent_name :test_agent

  def add_to_value_stored_in_agent(num) do
    new_val = get_value_from_agent() + num
    Agent.update(@agent_name, fn _ -> new_val end)
  end

  def get_value_from_agent() do
    Agent.get(@agent_name, &Function.identity/1)
  end

  def wait_for_task_to_succeed(ref) do
    assert_receive {:DOWN, ^ref, :process, _, :normal}, 500
  end

  setup do
    {:ok, pid} = Agent.start_link(fn -> 0 end, name: @agent_name)
    ~M[pid]
  end

  test "queue sends DOWN when task end", ~M[pid] do
    ref =
      Queue.enqueue("Sample Test", &add_to_value_stored_in_agent/1, [5], "dasmen")
      |> Process.monitor()

    assert_receive {:DOWN, ^ref, :process, _, :normal}, 500
    Agent.stop(pid)
  end

  @tag :flaky
  test "queue decrement slots when task is added", ~M[pid] do
    assert Queue.num_slots() == 5

    Queue.enqueue("Sample Test", &add_to_value_stored_in_agent/1, [5], "dasmen")
    |> Process.monitor()

    assert Queue.num_slots() == 4
    Agent.stop(pid)
  end

  test "queue creates a Task in the DB", ~M[pid] do
    ref =
      Queue.enqueue("Sample Test", &add_to_value_stored_in_agent/1, [5], "dasmen")
      |> Process.monitor()

    wait_for_task_to_succeed(ref)
    assert Repo.get_by(Task, description: "Sample Test", success: true)
    Agent.stop(pid)
  end

  test "queue accomplishes its given task", ~M[pid] do
    ref =
      Queue.enqueue("Sample Test", &add_to_value_stored_in_agent/1, [5], "dasmen")
      |> Process.monitor()

    wait_for_task_to_succeed(ref)
    assert get_value_from_agent() == 5
    Agent.stop(pid)
  end

  test "queue runs multiple tasks sequentially summing list of numbers", ~M[pid] do
    [5, 12, 18, 33, 17]
    |> Enum.reduce(
      0,
      fn value, sum ->
        ref =
          Queue.enqueue("Sample Test", &add_to_value_stored_in_agent/1, [value], "dasmen")
          |> Process.monitor()

        wait_for_task_to_succeed(ref)
        assert get_value_from_agent() == sum + value
        sum + value
      end
    )

    Agent.stop(pid)
  end

  test "Failing Task saves message in Task.error", ~M[pid] do
    ref =
      Queue.enqueue(
        "Sample Failure Test",
        &add_to_value_stored_in_agent/1,
        ["Oops, this will not work!"],
        "dasmen"
      )
      |> Process.monitor()

    wait_for_task_to_succeed(ref)

    assert Repo.get_by(
             Task,
             [
               description: "Sample Failure Test",
               error: "ArithmeticError: bad argument in arithmetic expression",
               success: false
             ],
             prefix: "dasmen"
           )

    Agent.stop(pid)
  end
end
