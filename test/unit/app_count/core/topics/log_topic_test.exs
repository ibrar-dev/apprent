defmodule AppCount.Core.LogTopicTest do
  use AppCount.DataCase
  alias AppCount.Core.LogTopic

  test "log broadcasts event" do
    LogTopic.subscribe()
    # When
    _domain_event = LogTopic.log!("content", __MODULE__)
    # Then
    assert_receive %{topic: "log"}
  end
end
