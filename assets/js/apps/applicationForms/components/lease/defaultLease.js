import moment from "moment";

export default (leaseParams) => {
  return {
    ...leaseParams,
    lease_date: leaseParams.lease_date || moment().format('YYYY-MM-DD'),
    unit_keys: leaseParams.unit_keys || 2,
    mail_keys: leaseParams.mail_keys || 2,
    other_keys: leaseParams.other_keys || 2,
    deposit_value: leaseParams.approval_params.deposit_amount,
    deposit_type: leaseParams.approval_params.deposit_type
  }
}
