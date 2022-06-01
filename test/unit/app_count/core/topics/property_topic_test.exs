defmodule AppCount.Core.PropertyTopicTest do
  @moduledoc false
  use AppCount.DataCase
  alias AppCount.Core.PropertyTopic
  alias AppCount.Core.DomainEvent

  def info() do
    %{property_id: 999}
  end

  describe "events" do
    setup do
      PropertyTopic.subscribe()
      info = info()

      ~M[info]
    end

    test "property_changed event", ~M[info] do
      # When
      _domain_event = PropertyTopic.property_changed(info, __MODULE__)

      # Then
      assert_receive %DomainEvent{
        topic: "property",
        name: "property_changed",
        content: %{property_id: 999},
        source: __MODULE__
      }
    end

    test "property_created event", ~M[info] do
      # When
      _domain_event = PropertyTopic.property_created(info, __MODULE__)

      # Then
      assert_receive %DomainEvent{
        topic: "property",
        name: "property_created",
        content: %{property_id: 999},
        source: __MODULE__
      }
    end
  end
end
