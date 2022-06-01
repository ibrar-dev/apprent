import {toCurr} from "../../../../utils";

const filterKey = {
  mo: "Money Order",
  ch: "Check",
  appl: "Application Fee",
  admin: "Administration Fee",
  appr: "AppRent Payment",
  mngrm: "MoneyGram Payment",
  successful_payments: "Successful Payments",
  failed_payments: "Failed Payments",
};

export const filterList = (batches, filters) => batches.reduce((acc, b) => {
  const {payments, other} = b.payments.reduce(
    ({payments, other}, p) => {
      if (filteredPayments(p, filters)) return {payments: payments.concat(p), other};
      return {payments, other: other.concat(p)};
    },
    {payments: [], other: []},
  );
  if (
    payments.length
      && (!filters.batch_date
        || moment(filters.batch_date).isSame(b.inserted_at, "day"))
  ) {
    return acc.concat({...b, payments, other});
  }
  return acc;
}, []);

const filteredPayments = (payment, filters) => {
  const testName = (pymt, regex) => (
    regex.test(pymt.tenant_name)
      || regex.test(pymt.payer)
      || (payment.persons?.length > 0 && pymt.persons.find((p) => regex.test(p.full_name)))
  );

  // If we don't want successful payments, filter 'em out
  if (!filters.types.successful_payments && !payment.post_error) return false;

  // If we don't want failed payments, filter 'em out
  if (!filters.types.failed_payments && payment.post_error) return false;

  // If we're filtering by unit and this one doesn't match, skip
  const unitRegex = RegExp(filters.unit, "i");
  if (filters.unit && !unitRegex.test(payment.unit)) return false;

  // If we're filtering by last_4 and this one doesn't match, skip
  const last4Regex = RegExp(filters.last_4, "i");
  if (filters.last_4 && !last4Regex.test(payment.payment_source_last_4)) return false;

  // If we're filtering by resident and this doesn't match, skip
  if (filters.resident) {
    const regex = new RegExp(filters.resident, "i");
    if (!testName(payment, regex)) return false;
  }

  // If we're filtering by TXN id and this doesn't match, skip
  if (
    filters.checkId
    && !new RegExp(filters.checkId).test(payment.transaction_id)
  ) return false;

  // If we're filtering by post month and this doesn't match, skip
  if (
    filters.post_month
    && moment(payment.post_month).format("MM/YYYY") !== filters.post_month
  ) return false;

  // If amount is less than min, exclude this payment
  if (payment.amount < parseFloat(filters.min)) return false;

  // If amount is greater than max, exclude this payment
  if (payment.amount > parseFloat(filters.max)) return false;

  return Object.keys(filters.types).some(
    (t) => filters.types[t] && payment.description === filterKey[t],
  );
};

export const initialFilter = {
  min: "",
  max: "",
  unit: "",
  last_4: "",
  resident: undefined,
  types: {
    mo: true,
    ch: true,
    appl: true,
    admin: true,
    appr: true,
    mngrm: true,
    successful_payments: true,
    failed_payments: true,
  },
};

export const buildCsv = (batches) => {
  const hdrs = [
    "Batch Date",
    "Payment Date",
    "Payer",
    "Amount",
    "Type",
    "Unit",
    "Deposit ID",
    "Check #",
  ];
  const arr = [];
  batches.forEach((batch) => {
    const batchDate = batch.inserted_at;
    batch.payments.forEach((val) => {
      arr.push([
        batchDate,
        val.inserted_at,
        val.tenant_name,
        toCurr(val.amount),
        val.description,
        val.unit || "NP",
        val.batch_id,
        val.transaction_id,
      ]);
    });
  });
  return [hdrs].concat(arr);
};