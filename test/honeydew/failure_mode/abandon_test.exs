defmodule Honeydew.FailureMode.AbandonTest do
  use ExUnit.Case, async: true

  setup do
    queue = :erlang.unique_integer
    {:ok, _} = Helper.start_queue_link(queue, failure_mode: Honeydew.FailureMode.Abandon)
    {:ok, _} = Helper.start_worker_link(queue, Stateless)

    [queue: queue]
  end

  test "should remove job from the queue", %{queue: queue} do
    {:crash, [self()]} |> Honeydew.async(queue)
    assert_receive :job_ran

    Process.sleep(100) # let the failure mode do its thing

    assert Honeydew.status(queue) |> get_in([:queue, :count]) == 0
    refute_receive :job_ran
  end

  test "should inform the awaiting process of the error", %{queue: queue} do
    {:error, reason} = {:crash, [self()]} |> Honeydew.async(queue, reply: true) |> Honeydew.yield
    assert {%RuntimeError{message: "ignore this crash"}, _stacktrace} = reason
  end
end
