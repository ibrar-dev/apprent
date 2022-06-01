defmodule AppCount.Leases.BlueMoonTest do
  use AppCount.DataCase
  alias AppCount.Leases
  alias AppCount.BlueMoonHelper
  alias AppCount.Support.HTTPClient

  @moduletag :leases_bluemoon

  setup do
    lease = AppCount.LeaseHelper.insert_lease()
    insert(:processor, property: lease.unit.property, name: "BlueMoon", type: "lease")
    {:ok, lease: lease}
  end

  test "execute_lease", %{lease: lease} do
    form = insert(:lease_form, lease: lease)
    BlueMoonHelper.mock_bluemoon_responses(["ExecuteLease"])
    assert Leases.execute_lease(form.id) == {:ok, "true"}
    HTTPClient.stop()
  end

  test "send_signature_request_for_lease", %{lease: lease} do
    original_form = insert(:lease_form, lease: lease)
    BlueMoonHelper.mock_bluemoon_responses(["RequestEsignature", "ListForms", "ListCustomForms"])
    new_admin = AppCount.UserHelper.new_admin()
    {:ok, form} = Leases.send_signature_request_for_lease(new_admin, lease.id)
    assert original_form.id == form.id
    HTTPClient.stop()
  end

  # TODO port this test
  #  test "sync_bluemoon_lease", %{lease: lease} do
  #    original_form = insert(:lease_form, lease: lease)
  #
  #    BlueMoonHelper.mock_bluemoon_responses([
  #      "EditLease",
  #      "ListForms",
  #      "ListCustomForms",
  #      "RequestEsignature"
  #    ])
  #
  #    {:ok, true} = Leases.sync_bluemoon_lease(%{name: "name", email: "email"}, original_form.id)
  #
  #    HTTPClient.stop()
  #  end

  test "request_bluemoon_signature", %{lease: lease} do
    original_form = insert(:lease_form, lease: lease)
    BlueMoonHelper.mock_bluemoon_responses(["ListForms", "ListCustomForms", "RequestEsignature"])

    params = %{
      admin: %{
        name: "Name",
        email: "email"
      },
      property_phone: "1234567890",
      bluemoon_id: "12345",
      residents: [],
      form: original_form
    }

    {:ok, form} =
      Leases.property_credentials(%{property_id: lease.unit.property_id})
      |> Leases.request_bluemoon_signature(params)

    assert original_form.id == form.id
    HTTPClient.stop()
  end

  test "signature_pdf", %{lease: lease} do
    BlueMoonHelper.mock_bluemoon_responses(["GetEsignaturePDF"])
    {:ok, base64} = Leases.signature_pdf(insert(:lease_form, lease: lease).id)

    assert AppCount.Data.file_type(Base.decode64!(base64)) == :pdf

    HTTPClient.stop()
  end

  test "get_bluemoon_url", %{lease: lease} do
    app = insert(:rent_application, property: lease.unit.property)
    url = Leases.get_bluemoon_url(insert(:lease_form, lease: nil, application: app).id)

    assert url =~ "https://"
  end

  test "save_form_pdf", %{lease: lease} do
    BlueMoonHelper.mock_bluemoon_responses(["GetEsignaturePDF"])
    {:ok, form} = Leases.save_form_pdf(insert(:lease_form, lease: lease).id)

    assert form.document_id

    HTTPClient.stop()
  end
end
