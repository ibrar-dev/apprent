defmodule AppCount.Core.PaymentTopicTest do
  @moduledoc false
  use AppCount.DataCase
  alias AppCount.Core.PaymentTopic
  alias AppCount.Core.DomainEvent

  def confirmed_content() do
    %AppCount.Core.ClientSchema{name: "dasmen", attrs: %{rent_saga_id: 999}}
  end

  def recorded_content() do
    %{
      rent_payment_id: 999,
      account_id: 888,
      line_items: []
    }
  end

  describe "events" do
    setup do
      PaymentTopic.subscribe()
      :ok
    end

    test "payment_confirmed event" do
      PaymentTopic.subscribe()
      content = confirmed_content()
      # When
      _domain_event = PaymentTopic.payment_confirmed(content, __MODULE__)

      # Then
      assert_receive %DomainEvent{
        topic: "payments",
        name: "payment_confirmed",
        content: %AppCount.Core.ClientSchema{name: "dasmen", attrs: %{rent_saga_id: 999}},
        source: __MODULE__
      }
    end

    test "payment_recorded event" do
      PaymentTopic.subscribe()
      content = recorded_content()

      # When
      _domain_event = PaymentTopic.payment_recorded(content, __MODULE__)

      # Then
      assert_receive %DomainEvent{
        topic: "payments",
        name: "payment_recorded",
        content: %{
          rent_payment_id: 999,
          account_id: 888,
          line_items: []
        },
        source: __MODULE__
      }
    end
  end
end
