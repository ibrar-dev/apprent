defmodule AppCount.Leases.FormsTest do
  use AppCount.DataCase
  alias AppCount.Leases

  @moduletag :leases_forms

  setup do
    {:ok, application: insert(:full_rent_application)}
  end

  test "forms CRUD", %{application: application} do
    {:ok, form} = Leases.create_form(%{"application_id" => application.id})
    today = AppCount.current_date()
    Leases.update_form(form.id, %{"lease_date" => today, "locked" => true})
    reloaded = Repo.get(Leases.Form, form.id)
    assert reloaded.lease_date == today
    assert Leases.update_form(form.id, %{"other_keys" => 4}) == {:error, :locked}
    Leases.unlock_form(reloaded.id)
    assert Repo.get(Leases.Form, form.id).locked == false
  end

  test "get_application_lease_form", %{application: application} do
    result = Leases.get_application_lease_form(application.id)
    assert result.application_id == application.id
  end

  test "create_form_from_bluemoon", %{application: application} do
    insert(:processor, property: application.property, name: "BlueMoon")
    lease = AppCount.LeaseHelper.insert_lease(%{property: application.property})
    AppCount.BlueMoonHelper.mock_bluemoon_responses(["GetLeaseXMLData"])

    {:ok, %{lease: updated}} =
      Leases.create_form_from_bluemoon(%{
        "lease_id" => lease.id,
        "bluemoon_id" => "12345",
        "signature_id" => "12345"
      })

    AppCount.Support.HTTPClient.stop()
    assert updated.bluemoon_lease_id == "12345"
    assert updated.bluemoon_signature_id == "12345"
  end
end
