defmodule AppCount.Leases do
  alias AppCount.Leases.Utils.Reports
  alias AppCount.Leases.Utils.Screenings
  alias AppCount.Leases.Utils.Forms
  alias AppCount.Leases.Utils.Leases
  alias AppCount.Leases.Utils.BlueMoon
  alias AppCount.Leases.Utils.Renewals
  alias AppCount.Leases.Utils.Charges

  def create_lease(params), do: Leases.create_lease(params)
  def update_lease(id, params), do: Leases.update_lease(id, params)
  def update_leases(lease_ids, params), do: Leases.update_leases(lease_ids, params)
  def delete_lease(admin, lease_id), do: Leases.delete_lease(admin, lease_id)
  def create_sec_dep_charge(lease), do: Leases.create_sec_dep_charge(lease)
  def document_url(lease_id), do: Leases.document_url(lease_id)
  def lock_lease(id, params), do: Leases.lock_lease(id, params)
  def unlock_lease(lease_id), do: Leases.unlock_lease(lease_id)
  def save_lease_pdf(lease_id), do: Leases.save_lease_pdf(lease_id)

  def update_charges(admin, lease_id, params), do: Charges.update_charges(admin, lease_id, params)

  def new_lease_from_bluemoon_xml(lease, params),
    do: Renewals.new_lease_from_bluemoon_xml(lease, params)

  def get_leases(property_id, start_date, end_date),
    do: Reports.get_leases(property_id, start_date, end_date)

  def renewal_report(admin, property_id), do: Reports.renewal_report(admin, property_id)

  def create_screening(params, instant_screen \\ false, schema),
    do: Screenings.create_screening(params, instant_screen, schema)

  def get_screening_status(id), do: Screenings.get_screening_status(id)
  def handle_postback(params), do: Screenings.handle_postback(params)
  def delete_screening(id), do: Screenings.delete_screening(id)
  def approve_screening(id), do: Screenings.approve_screening(id)
  def adverse_action_params(screening_id), do: Screenings.adverse_action_params(screening_id)

  def create_form(params), do: Forms.create_form(params)
  def create_form_from_bluemoon(params), do: Forms.create_form_from_bluemoon(params)
  def update_form(id, params), do: Forms.update_form(id, params)
  def unlock_form(id), do: Forms.unlock_form(id)

  def get_application_lease_form(application_id),
    do: Forms.get_application_lease_form(application_id)

  def execute_lease(lease_id), do: BlueMoon.execute_lease(lease_id)
  def get_signature_status(form_id), do: BlueMoon.get_signature_status(form_id)

  def send_signature_request_for_lease(admin, lease_id),
    do: BlueMoon.send_signature_request_for_lease(admin, lease_id)

  def request_bluemoon_signature(credentials, params),
    do: BlueMoon.request_bluemoon_signature(credentials, params)

  def get_bluemoon_lease(lease_id, form_id), do: BlueMoon.get_bluemoon_lease(lease_id, form_id)
  def sync_bluemoon_lease(admin, form_id), do: BlueMoon.sync_bluemoon_lease(admin, form_id)
  def signature_pdf(lease_id), do: BlueMoon.signature_pdf(lease_id)
  def get_bluemoon_url(lease_id), do: BlueMoon.get_bluemoon_url(lease_id)
  def save_form_pdf(form_id), do: BlueMoon.save_form_pdf(form_id)
  def property_credentials(params), do: BlueMoon.property_credentials(params)
end
