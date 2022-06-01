defmodule AppCount.Reports do
  alias AppCount.Exports.AccountingReport
  alias AppCount.Exports.AccountDetailReport
  alias AppCount.Exports.DQReport
  alias AppCount.Exports.GrossPotentialRentExcel
  alias AppCount.Reports.Index
  alias AppCount.Reports.BoxScore
  alias AppCount.Reports.MaintenanceReport
  alias AppCount.Reports.AgingReport
  alias AppCount.Reports.RentRoll
  alias AppCount.Reports.MoveOuts
  alias AppCount.Reports.Delinquency
  alias AppCount.Reports.Availability
  alias AppCount.Reports.BoxScore
  alias AppCount.Reports.MonthToMonth
  alias AppCount.Reports.DailyDeposit
  alias AppCount.Reports.ExpiringLeases
  alias AppCount.Reports.GrossPotentialRent
  alias AppCount.Reports.AdminPaymentsAndCharges

  def run_report(id, params), do: apply(Index.report_module(id), :run, [params])

  def accounting_report_excel(
        id,
        property_ids,
        book,
        suppress_zeros,
        start_date,
        end_date \\ nil
      ),
      do:
        AccountingReport.accounting_report_excel(
          id,
          property_ids,
          book,
          suppress_zeros,
          start_date,
          end_date
        )

  def dq_report_excel(property_id, filters, ar, date),
    do: DQReport.dq_report_excel(property_id, filters, ar, date)

  def gross_potential_rent(property_id, start_date, post_month),
    do: GrossPotentialRent.run(property_id, start_date, post_month)

  def gross_potential_rent_excel(property_id, start_date, post_month),
    do: GrossPotentialRentExcel.run(property_id, start_date, post_month)

  def account_detail_excel(params, name, title),
    do: AccountDetailReport.account_detail_excel(params, name, title)

  def delinquency_report(property_id, date \\ nil),
    do: Delinquency.delinquency_report(property_id, date)

  def collection_report(property_id, date), do: Delinquency.collection_report(property_id, date)

  def availability_report(admin, property_id),
    do: Availability.availability_report(admin, property_id)

  def box_score(_admin, property_id, dates, type),
    do: AppCount.Reports.Property.BoxScore.box_score(property_id, dates, type)

  #  def box_score(admin, property_id, start_date, end_date),
  #      do: BoxScore.box_score_report(admin, property_id, start_date, end_date)

  def mtm_report(admin, property_id), do: MonthToMonth.mtm_report(admin, property_id)
  def rent_roll(admin, property_id), do: RentRoll.rent_roll(admin, property_id)
  def rent_roll(admin, property_id, date), do: RentRoll.rent_roll(admin, property_id, date)

  def find_applicants_report(admin, property_id, start_date, end_date),
    do: BoxScore.find_applicants_report(admin, property_id, start_date, end_date)

  def move_outs_report(admin, property_id, start, end_date),
    do: MoveOuts.report(admin, property_id, start, end_date)

  def open_make_ready_report(admin), do: MaintenanceReport.open_make_ready_report(admin)

  def open_make_ready_report(admin, date),
    do: MaintenanceReport.open_make_ready_report(admin, date)

  def property_metrics(admin, start_date, end_date),
    do: MaintenanceReport.property_metrics(admin, start_date, end_date)

  def admin_payments_and_charges(admin_id, start_date, end_date),
    do: AdminPaymentsAndCharges.index(admin_id, start_date, end_date)

  def daily_deposit(admin, property_id), do: DailyDeposit.daily_deposit(admin, property_id)

  def daily_deposit(admin, property_id, date),
    do: DailyDeposit.daily_deposit(admin, property_id, date)

  def aging_report(admin, property_id, date \\ nil),
    do: AgingReport.aging_report(admin, property_id, date)

  def expiring_leases_report(property_id, date \\ nil),
    do: ExpiringLeases.run_report(property_id, date)
end
