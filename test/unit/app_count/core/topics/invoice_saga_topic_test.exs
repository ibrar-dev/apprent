defmodule AppCount.Core.InvoiceSagaTopicTest do
  @moduledoc false
  use AppCount.DataCase
  alias AppCount.Core.InvoiceSagaTopic
  alias AppCount.Core.DomainEvent

  def info() do
    %{property_id: 999}
  end

  describe "events" do
    setup do
      InvoiceSagaTopic.subscribe()
      :ok
    end

    test "saga completed event" do
      rent_application_id = 123
      # When
      _domain_event =
        InvoiceSagaTopic.completed(
          {"AppCount.RentApply.RentApplication", rent_application_id},
          %{status: :error},
          __MODULE__
        )

      # Then
      assert_receive %DomainEvent{
        topic: "invoice_saga",
        name: "completed",
        content: %{status: :error},
        subject_id: ^rent_application_id,
        subject_name: "AppCount.RentApply.RentApplication",
        source: __MODULE__
      }
    end
  end
end
