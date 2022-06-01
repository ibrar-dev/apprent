defmodule AppCount.Core.RentApplicationTopicTest do
  @moduledoc false
  use AppCount.DataCase
  alias AppCount.Core.RentApplicationTopic
  alias AppCount.Core.DomainEvent

  def info() do
    %{property_id: 999}
  end

  describe "events" do
    setup do
      RentApplicationTopic.subscribe()
      :ok
    end

    test "created event" do
      rent_application_id = 123
      content = %{line_items: [], account_id: 0}
      # When
      _domain_event = RentApplicationTopic.created(rent_application_id, content, __MODULE__)

      # Then
      assert_receive %DomainEvent{
        topic: "rent_apply__rent_applications",
        name: "created",
        content: %{line_items: [], account_id: 0},
        subject_id: ^rent_application_id,
        subject_name: "AppCount.RentApply.RentApplication",
        source: __MODULE__
      }
    end
  end
end
