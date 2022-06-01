defmodule AppCount.Core.OrderTopicTest do
  use AppCount.DataCase
  alias AppCount.Core.OrderTopic
  alias AppCount.Core.DomainEvent
  alias AppCount.Core.OrderTopic.Info

  def info() do
    %Info{
      phone_to: "+15135551234",
      account_allow_sms: true,
      order_allow_sms: true,
      order_id: 5,
      first_name: "Mickey",
      work_order_category_name: "work_order_category_name",
      property_name: "Lake View Apartments"
    }
  end

  describe "events" do
    setup do
      OrderTopic.subscribe()
      info = info()

      ~M[info]
    end

    test "order_created event", ~M[info] do
      OrderTopic.subscribe()
      # When
      _domain_event = OrderTopic.order_created(info, __MODULE__)

      # Then
      assert_receive %DomainEvent{
        topic: "order",
        name: "order_created",
        content: %{},
        source: __MODULE__
      }
    end

    test "order_assigned event", ~M[info] do
      _domain_event = OrderTopic.order_assigned(info, __MODULE__)

      assert_receive %DomainEvent{
        topic: "order",
        name: "order_assigned",
        content: ^info,
        source: __MODULE__
      }
    end

    test "tech_dispatched event", ~M[info] do
      _domain_event = OrderTopic.tech_dispatched(info, __MODULE__)

      assert_receive %DomainEvent{
        topic: "order",
        name: "tech_dispatched",
        content: ^info,
        source: __MODULE__
      }
    end

    test "order_completed event", ~M[info] do
      _domain_event = OrderTopic.order_completed(info, __MODULE__)

      assert_receive %DomainEvent{
        topic: "order",
        name: "order_completed",
        content: ^info,
        source: __MODULE__
      }
    end
  end
end
