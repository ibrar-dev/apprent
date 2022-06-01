defmodule AppCount.Maintenance do
  alias AppCount.Maintenance.Utils.Assignments
  alias AppCount.Maintenance.Utils.Auth
  alias AppCount.Maintenance.Utils.Cards
  alias AppCount.Maintenance.Utils.Categories
  alias AppCount.Maintenance.Utils.Notes
  alias AppCount.Maintenance.Utils.OpenHistories
  alias AppCount.Maintenance.Utils.Orders
  alias AppCount.Maintenance.Utils.PaidTimes
  alias AppCount.Maintenance.Utils.Parts
  alias AppCount.Maintenance.Utils.Queries
  alias AppCount.Maintenance.Utils.RecurringOrders
  alias AppCount.Maintenance.Utils.Reports
  alias AppCount.Maintenance.Utils.Techs
  alias AppCount.Maintenance.Utils.Timecards
  alias AppCount.Maintenance.NoteRepo, as: MaintenanceNoteRepo
  alias AppCount.Maintenance.Utils.Queries.V1.Techs, as: V1Techs
  alias AppCount.Maintenance.Utils.V1.Categories, as: V1Categories
  alias AppCount.Vendors.NoteRepo, as: VendorsNoteRepo
  alias AppCount.Core.ClientSchema
  ## Techs
  def list_techs(admin, type), do: Techs.list_techs(admin, type)
  def list_techs(admin), do: Techs.list_techs(admin)
  def create_tech(params), do: Techs.create_tech(params)
  def update_tech(id, params), do: Techs.update_tech(id, params)
  def delete_tech(id), do: Techs.delete_tech(id)
  def set_tech_coords(tech_id, coords), do: Techs.set_tech_coords(tech_id, coords)
  def tech_details(id), do: Techs.tech_details(id)
  def log_on(tech_id), do: Techs.log_on(tech_id)
  def log_off(tech_id), do: Techs.log_off(tech_id)
  def tech_info(tech_id), do: Techs.tech_info(tech_id)
  def tech_detailed_info(tech_id), do: Techs.tech_detailed_info(tech_id)
  def last_six_months(tech_id), do: Techs.last_six_months(tech_id)
  def set_all_categories(tech_id), do: Techs.set_all_categories(tech_id)
  def get_active_techs(admin, date), do: Techs.get_active_techs(admin, date)

  ## Timecards
  def clock(tech_id, params), do: Timecards.clock(tech_id, params)
  def list_hours(tech_id), do: Timecards.list_hours(tech_id)

  def get_admin_day(admin, start_date, end_date \\ nil),
    do: Timecards.get_admin_day(admin, start_date, end_date)

  def get_tech_status(tech_id), do: Timecards.get_tech_status(tech_id)
  def update_timecard(id, params), do: Timecards.update_timecard(id, params)
  def create_timecard(params), do: Timecards.create_timecard(params)

  ## PaidTimes
  def create_paid_time(params), do: PaidTimes.create_paid_time(params)
  def update_paid_time(id, params), do: PaidTimes.update_paid_time(id, params)
  def delete_paid_time(id), do: PaidTimes.delete_paid_time(id)
  def list_paid_times(admin), do: PaidTimes.list_paid_times(admin)

  def list_orders(property_id, start_date, end_date),
    do: Orders.list_orders(property_id, start_date, end_date)

  def get_order(admin, id), do: Orders.get_order(admin, id)
  def get_order_tenant(property_id, id), do: Orders.get_order_tenant(property_id, id)
  def create_order(admin_id, attrs), do: Orders.create_order(admin_id, attrs)
  def create_order(attrs), do: Orders.create_order(attrs)

  def delete_order(admin, id, reason), do: Orders.delete_order(admin, id, reason)
  def update_order(id, attrs), do: Orders.update_order(id, attrs)
  def no_access(tech, id), do: Orders.no_access(tech, id)
  def email_resident(admin, params), do: Orders.email_resident(admin, params)
  def get_tenants_orders(id), do: Orders.get_tenants_orders(id)

  ## SnapShots
  def daily_snapshot(id, date), do: Orders.daily_snapshot(id, date)

  def daily_snapshot(id, start_date, end_date),
    do: Orders.daily_snapshot(id, start_date, end_date)

  def admin_daily_snapshot(admin, date), do: Orders.admin_daily_snapshot(admin, date)

  ## Assignments
  def assign_order(order_id, tech_id, admin_id),
    do: Assignments.assign_order(order_id, tech_id, admin_id)

  def assign_orders(order_ids, tech_id, admin_id),
    do: Assignments.assign_orders(order_ids, tech_id, admin_id)

  def revoke_assignment(assignment_id), do: Assignments.revoke_assignment(assignment_id)
  def revoke_assignments(assignment_ids), do: Assignments.revoke_assignments(assignment_ids)

  def reject_assignment(assignment_id, reason),
    do: Assignments.reject_assignment(assignment_id, reason)

  def accept_assignment(assignment_id), do: Assignments.accept_assignment(assignment_id)

  def attach_material(id, num, assignment_id),
    do: Assignments.attach_material(id, num, assignment_id)

  def remove_material(assignment_id, material),
    do: Assignments.remove_material(assignment_id, material)

  def complete_assignment(assignment_id, details),
    do: Assignments.complete_assignment(assignment_id, details)

  def complete_assignment(assignment_id, details, tech_id),
    do: Assignments.complete_assignment(assignment_id, details, tech_id)

  def rate_assignment(assignment_id, rating),
    do: Assignments.rate_assignment(assignment_id, rating)

  def resident_callback_assignment(assignment, note),
    do: Assignments.resident_callback_assignment(assignment, note)

  def callback_assignment(assignment, admin, note),
    do: Assignments.callback_assignment(assignment, admin, note)

  def callback_assignment(assignment), do: Assignments.callback_assignment(assignment)
  def pause_assignment(assignment_id), do: Assignments.pause_assignment(assignment_id)
  def resume_assignment(assignment_id), do: Assignments.resume_assignment(assignment_id)

  def tech_dispatched(assignment_id, time),
    do: Assignments.tech_dispatched(assignment_id, time)

  def bug_resident_about_rating(admin, assignment_id),
    do: Assignments.bug_resident_about_rating(admin, assignment_id)

  def delete_assignment(admin, assignment_id),
    do: Assignments.delete_assignment(admin, assignment_id)

  ## Categories

  def list_categories({type, client_schema}),
    do: Categories.list_categories({type, client_schema})

  def list_categories(client_schema), do: Categories.list_categories(client_schema)
  def create_category(attrs), do: Categories.create_category(attrs)
  def update_category(id, attrs), do: Categories.update_category(id, attrs)
  def delete_category(id), do: Categories.delete_category(id)
  def transfer(from_id, to_id), do: Categories.transfer(from_id, to_id)
  def get_best_cat_id(note), do: Google.Maintenance.get_cat_id_from_note(note)
  def get_best_cat_ids(note), do: Google.Maintenance.get_cat_ids_from_note(note)

  ## Notes

  def create_note(attrs), do: Notes.create_note(attrs)
  def delete_note(id), do: Notes.delete_note(id)
  def create_tech_note(assignment_id, msg), do: Notes.create_tech_note(assignment_id, msg)
  def get_maintenance_notes(order_id, access), do: MaintenanceNoteRepo.get_notes(order_id, access)
  def get_vendor_notes(order_id), do: VendorsNoteRepo.get_notes(order_id)

  ## Recurring Orders

  def list_recurring_orders(admin), do: RecurringOrders.list_recurring_orders(admin)
  def create_recurring_order(params), do: RecurringOrders.create_recurring_order(params)
  def update_recurring_order(id, params), do: RecurringOrders.update_recurring_order(id, params)
  def delete_recurring_order(id), do: RecurringOrders.delete_recurring_order(id)

  ## Cards

  def create_card(params), do: Cards.create_card(params)
  def list_cards(admin, property_ids, hidden), do: Cards.list_cards(admin, property_ids, hidden)
  def update_card(id, params), do: Cards.update_card(id, params)
  def not_ready_units(admin), do: Cards.not_ready_units(admin)

  def create_card_item(params, admin), do: Cards.create_card_item(params, admin)

  def update_card_item(id, params, update_type \\ :updated),
    do: Cards.update_card_item(id, params, update_type)

  def confirm_card_item(id, params, admin), do: Cards.confirm_card_item(id, params, admin)
  def complete_card_item(id, params), do: Cards.complete_card_item(id, params)
  def complete_card_item(id, params, admin), do: Cards.complete_card_item(id, params, admin)
  def revert_card_item(id, params), do: Cards.revert_card_item(id, params)
  def delete_card_item(admin, id), do: Cards.delete_card_item(admin, id)

  def get_ready_by_dates(admin, start_date, end_date \\ nil),
    do: Cards.get_ready_by_dates(admin, start_date, end_date)

  def list_last_domain_event(card_ids),
    do: AppCount.Maintenance.CardRepo.list_last_domain_event(card_ids)

  ## AppWork

  def cert_for_passcode(code), do: Auth.cert_for_passcode(code)
  def authenticate_tech(cert), do: Auth.authenticate_tech(cert)
  def tech_data(tech_id), do: Techs.tech_data(tech_id)
  def tech_order_data(tech_id, order_id), do: Techs.tech_order_data(tech_id, order_id)
  def set_pass_code(tech_id), do: Techs.set_pass_code(tech_id)

  ## Reports
  def unit_report(admin), do: Reports.unit_report(admin)
  def property_report(admin), do: Reports.property_report(admin)
  def info_for_daily_report(admin), do: Orders.info_for_daily_report(admin)
  def send_daily_report(notes, admins, admin), do: Reports.send_daily_report(notes, admins, admin)

  def property_stats_query_by_admin_six_months(admin_id),
    do: Reports.property_stats_query_by_admin_six_months(admin_id)

  def property_stats_query_by_admin_six_months(admin_id, property_id),
    do: Reports.property_stats_query_by_admin_six_months(admin_id, property_id)

  def admin_completed(admin, date), do: Reports.admin_completed(admin, date)

  def admin_completed(admin, start_date, end_date),
    do: Reports.admin_completed(admin, start_date, end_date)

  def admin_categories(admin, date), do: Reports.admin_categories(admin, date)

  def admin_categories(admin, start_date, end_date),
    do: Reports.admin_categories(admin, start_date, end_date)

  def admin_categories_completed(admin, date), do: Reports.admin_categories_completed(admin, date)

  def admin_categories_completed(admin, start_date, end_date),
    do: Reports.admin_categories_completed(admin, start_date, end_date)

  def tech_report(params), do: Reports.tech_report(params)

  def make_ready_report(admin, start_date, end_date),
    do: Reports.make_ready_report(admin, start_date, end_date)

  ## Parts
  def create_part(params), do: Parts.create_part(params)
  def update_part(id, params), do: Parts.update_part(id, params)
  def update_parts(parts), do: Parts.update_parts(parts)
  def remove_part(id), do: Parts.remove_part(id)

  ## Open Histories
  #  def create_all_job(), do: OpenHistories.create_all_job()
  def list_open_histories(admin, date), do: OpenHistories.list_open_histories(admin, date)

  def list_open_histories(admin, start_date, end_date),
    do: OpenHistories.list_open_histories(admin, start_date, end_date)

  ## NEW ORDERS
  # Why if we pass in a ClientSchema are we then declaring a new one online 237?
  def list_orders_new(admin, dates, %AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: property_ids
      }),
      do: Queries.list_orders(admin, dates, ClientSchema.new(client_schema, property_ids))

  def list_orders_type(property_id, type),
    do: Queries.list_orders_type(property_id, type)

  def show_order(admin, id), do: Queries.show_order(admin, id)

  ## New Analytics
  def get_analytics(dates, property_ids, type),
    do: Queries.get_analytics(dates, property_ids, type)

  ## Public
  def get_order_public(uuid, type), do: AppCount.Maintenance.Utils.Public.get_order(uuid, type)

  ## V1
  def v1_list_categories(client_schema), do: V1Categories.list_categories(client_schema)

  def v1_list_techs(admin), do: V1Techs.list_techs(admin)
  def v1_get_tech(admin, id), do: V1Techs.show_tech(admin, id)
  def v1_update_tech(admin, id, attributes), do: V1Techs.update_tech(admin, id, attributes)
end
