defmodule AppCount.Properties.Utils.ResidentEventAttendancesTest do
  use AppCount.DataCase
  alias AppCount.Properties
  @moduletag :properties_resident_event_attendances

  setup do
    {:ok, event: insert(:resident_event), tenant: insert(:tenant)}
  end

  test "create_resident_event_attendance", %{event: event, tenant: tenant} do
    %{"tenant_id" => tenant.id, "resident_event_id" => event.id}
    |> Properties.create_resident_event_attendance()

    assert Repo.get_by(Properties.ResidentEventAttendance,
             tenant_id: tenant.id,
             resident_event_id: event.id
           )
  end
end
