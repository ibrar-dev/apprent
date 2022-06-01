defmodule AppCount.Properties.ResidentEventsTest do
  use AppCount.DataCase
  alias AppCount.Properties
  @moduletag :properties_resident_events

  setup do
    {:ok, event: insert(:resident_event)}
  end

  test "list_resident_events", %{event: event} do
    [result] = Properties.list_resident_events(event.property.id)
    assert result.id == event.id
    assert result.property.address
    assert result.start_time == event.start_time
    [result] = Properties.list_resident_events(event.property.id, :upcoming)
    assert result.id == event.id
    assert result.property.address
    assert result.start_time == event.start_time
  end
end
