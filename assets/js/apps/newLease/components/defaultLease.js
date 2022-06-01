import moment from "moment";

export default (leaseParams) => {
  return {
    unit_keys: 2,
    mail_keys: 2,
    other_keys: 2,
    residents: [],
    occupants: [],
    signators: [],
    concession_months: [],
    fitness_card_numbers: [],
    ...leaseParams,
    lease_date: moment().format('YYYY-MM-DD'),
    start_date: leaseParams.start_date ? moment(leaseParams.start_date).add(1, "days").format('YYYY-MM-DD') : null,
    end_date: leaseParams.end_date ? moment(leaseParams.end_date).add(1, "days").format('YYYY-MM-DD') : null
  }
}