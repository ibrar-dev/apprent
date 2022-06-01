defmodule AppCount.Properties do
  alias AppCount.Properties.Utils.AdminDocuments
  alias AppCount.Properties.Utils.Calculations
  alias AppCount.Properties.Utils.Charges
  alias AppCount.Properties.Utils.Config
  alias AppCount.Properties.Utils.Documents
  alias AppCount.Properties.Utils.Events
  alias AppCount.Properties.Utils.Evictions
  alias AppCount.Properties.Utils.Features
  alias AppCount.Properties.Utils.FloorPlans
  alias AppCount.Properties.Utils.LetterTemplates
  alias AppCount.Properties.Utils.Occupants
  alias AppCount.Properties.Utils.Packages
  alias AppCount.Properties.Utils.PhoneLines
  alias AppCount.Properties.Utils.Processors
  alias AppCount.Properties.Utils.Properties
  alias AppCount.Properties.Utils.PropertyAdminDocuments
  alias AppCount.Properties.Utils.RecurringLetters
  alias AppCount.Properties.Utils.Regions
  alias AppCount.Properties.Utils.Reports
  alias AppCount.Properties.Utils.ResidentEventAttendances
  alias AppCount.Properties.Utils.ResidentEvents
  alias AppCount.Properties.Utils.Settings
  alias AppCount.Properties.Utils.Units
  alias AppCount.Properties.Utils.Visits

  def list_properties(admin, :min), do: Properties.list_properties(admin, :min)
  def list_properties(admin), do: Properties.list_properties(admin)
  def list_active_properties(admin), do: Properties.list_active_properties(admin)

  # DO NOT DELETE THE BELOW FUNCTION. IT IS USED BY A MOBILE APP
  def list_public_properties(client_schema), do: Properties.list_public_properties(client_schema)
  def get_property(admin, id), do: Properties.get_property(admin, id)
  def get_property(arg), do: Properties.get_property(arg)

  def get_property_with_payment_keys(arg, schema),
    do: Properties.get_property_with_payment_keys(arg, schema)

  def create_property(params), do: Properties.create_property(params)
  def update_property(id, params), do: Properties.update_property(id, params)
  def delete_property(id), do: Properties.delete_property(id)
  def public_property_data(code), do: Properties.public_property_data(code)
  def property_info(id), do: Properties.property_info(id)
  def agreement_text_for(prop), do: Settings.agreement_text_for(prop)

  def check_property_configuration(property_ids),
    do: Config.check_property_configuration(property_ids)

  def list_units(admin, property_id), do: Units.list_units(admin, property_id)

  def list_units_min(admin, property_ids \\ nil, start_date \\ nil),
    do: Units.list_units_min(admin, property_ids, start_date)

  def create_unit(params), do: Units.create_unit(params)
  def update_unit(id, params), do: Units.update_unit(id, params)
  def delete_unit(id), do: Units.delete_unit(id)
  def get_unit(id \\ nil), do: Units.get_unit(id)
  def list_rentable(admin), do: Units.list_rentable(admin)
  def unit_rent(unit_id), do: Units.unit_rent(unit_id)
  def show_unit(admin, id), do: Units.show_unit(admin, id)
  def market_rent(unit_id), do: Units.market_rent(unit_id)

  def get_available_units(property_id, start_date),
    do: Units.get_available_units(property_id, start_date)

  def search_units(admin), do: Units.search_units(admin)
  def search_units(admin, term), do: Units.search_units(admin, term)

  def list_features(admin), do: Features.list_features(admin)
  def create_feature(params), do: Features.create_feature(params)
  def update_feature(id, params), do: Features.update_feature(id, params)
  def delete_feature(id), do: Features.delete_feature(id)

  def list_visits(admin), do: Visits.list_visits(admin)
  def create_visit(params), do: Visits.create_visit(params)
  #  def update_visit(id, params), do: Visits.update_visit(id, params)
  def delete_visit(id), do: Visits.delete_visit(id)

  def create_charge(params), do: Charges.create_charge(params)
  def update_charge(admin, id, params), do: Charges.update_charge(admin, id, params)
  def delete_charge(id), do: Charges.delete_charge(id)

  def list_floor_plans(admin), do: FloorPlans.list_floor_plans(admin)
  def create_floor_plan(params), do: FloorPlans.create_floor_plan(params)
  def update_floor_plan(id, params), do: FloorPlans.update_floor_plan(id, params)
  def delete_floor_plan(id), do: FloorPlans.delete_floor_plan(id)
  def floor_plan_market_rent(id), do: FloorPlans.floor_plan_market_rent(id)

  def create_package(params), do: Packages.create_package(params)
  def list_packages(admin, property_ids \\ nil), do: Packages.list_packages(admin, property_ids)
  def update_package(id, params), do: Packages.update_package(id, params)
  def delete_package(id), do: Packages.delete_package(id)

  def list_events(admin_or_property_ids), do: Events.list_events(admin_or_property_ids)

  def list_documents(tenant_id), do: Documents.list_documents(tenant_id)
  def create_document(params), do: Documents.create_document(params)
  def update_document(id, params), do: Documents.update_document(id, params)
  def delete_document(id), do: Documents.delete_document(id)

  def create_admin_document(params),
    do: AdminDocuments.create_admin_document(params)

  def update_admin_document(id, params),
    do: AdminDocuments.update_admin_document(id, params)

  def delete_admin_document(admin, id),
    do: AdminDocuments.delete_admin_document(admin, id)

  def find_documents(property_ids), do: PropertyAdminDocuments.find_documents(property_ids)

  def create_eviction(params), do: Evictions.create_eviction(params)
  def update_eviction(id, params), do: Evictions.update_eviction(id, params)
  def delete_eviction(id), do: Evictions.delete_eviction(id)

  def property_report(admin), do: Reports.property_report(admin)
  def specific_property_report(property_ids), do: Reports.specific_property_report(property_ids)

  # USED?
  def list_processors(), do: Processors.list_processors()
  # ^USED?
  def list_processors(params), do: Processors.list_processors(params)
  def create_processor(params), do: Processors.create_processor(params)

  def create_payscape_account_and_processor(account, params),
    do: Processors.create_payscape_account_and_processor(account, params)

  def update_processor(id, params), do: Processors.update_processor(id, params)
  def delete_processor(id), do: Processors.delete_processor(id)
  def can_instant_screen(property_id), do: Processors.can_instant_screen(property_id)

  def get_bluemoon_property_ids(processor_id),
    do: Processors.get_bluemoon_property_ids(processor_id)

  ########## PERSONS
  def create_occupant(params), do: Occupants.create_occupant(params)
  def update_occupant(id, params), do: Occupants.update_occupant(id, params)
  def delete_occupant(admin, id), do: Occupants.delete_occupant(admin, id)

  ########## RESIDENT EVENTS
  def list_resident_events(property_id), do: ResidentEvents.list_resident_events(property_id)

  def list_resident_events(property_id, :upcoming),
    do: ResidentEvents.list_resident_events(property_id, :upcoming)

  def show_resident_event(id), do: ResidentEvents.show_resident_event(id)
  def create_resident_event(params), do: ResidentEvents.create_resident_event(params)
  def update_resident_event(id, params), do: ResidentEvents.update_resident_event(id, params)
  def delete_resident_event(id), do: ResidentEvents.delete_resident_event(id)

  def create_resident_event_attendance(params),
    do: ResidentEventAttendances.create_resident_event_attendance(params)

  ########## RESIDENT FUNCTIONS
  def list_resident_packages(tenant_id), do: Packages.list_resident_packages(tenant_id)

  ########## CALCULATIONS
  def calculate_trend(property_ids, days), do: Calculations.calculate_trend(property_ids, days)

  def calculate_trend_detailed(property_ids, days),
    do: Calculations.calculate_trend_detailed(property_ids, days)

  def calculate_trend_multiple(property_ids),
    do: Calculations.calculate_trend_multiple(property_ids)

  ########## LETTER TEMPLATES
  def get_letter_templates(property_id), do: LetterTemplates.get_letter_templates(property_id)
  def create_letter_template(params), do: LetterTemplates.create_letter_template(params)
  def update_letter_template(id, params), do: LetterTemplates.update_letter_template(id, params)
  def delete_letter_template(id), do: LetterTemplates.delete_letter_template(id)

  ########## RECURRING LETTERS
  def list_recurring_letters(admin, property_id),
    do: RecurringLetters.list_recurring_letters(admin, property_id)

  def create_recurring_letter(params), do: RecurringLetters.create_recurring_letter(params)

  def update_recurring_letter(id, params),
    do: RecurringLetters.update_recurring_letter(id, params)

  def delete_recurring_letter(id), do: RecurringLetters.delete_recurring_letter(id)
  def run_recurring_letters_early(id), do: RecurringLetters.run_recurring_letters_early(id)

  ########## Phone Lines
  def list_phone_lines(property_id), do: PhoneLines.list_phone_lines(property_id)
  def create_phone_line(params), do: PhoneLines.create_phone_line(params)
  def update_phone_line(id, params), do: PhoneLines.update_phone_line(id, params)
  def delete_phone_line(id), do: PhoneLines.delete_phone_line(id)

  ########## Regions
  def create_region(params), do: Regions.create(params)
  def update_region(id, params), do: Regions.update(id, params)
  def list_regions(), do: Regions.list_regions()
end
