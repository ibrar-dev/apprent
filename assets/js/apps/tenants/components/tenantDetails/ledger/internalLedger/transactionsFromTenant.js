import moment from "moment";

const chargeTs = (item) => {
  item.ts = (item.isPayment || item.desc) ? parseInt(moment(item.inserted_at).format('X')) : parseInt(moment(item.bill_date).format('X'));
  return item.ts;
};

const transactionsFromTenant = ({leases}) => {
  const ledgers = {};
  let latest = null;
  let lastTs = 0;
  leases.forEach(lease => {
    const {payments, bills} = lease;
    payments.forEach(p => p.isPayment = true);
    ledgers[lease.unit.number] = (ledgers[lease.unit.number] || []).concat(bills).concat(payments);
  });

  Object.keys(ledgers).forEach(u => {
    ledgers[u].sort((a, b) => chargeTs(a) - chargeTs(b) || (a.account < b.account ? -1 : 1));
    const transactions = ledgers[u];
    if (transactions.length > 0) {
      const lastTransaction = ledgers[u][ledgers[u].length - 1].ts;
      if (lastTransaction > lastTs) {
        lastTs = lastTransaction;
        latest = u;
      }
    }
  });
  return {ledgers, latest: latest || Object.keys(ledgers)[0]};
};

export default transactionsFromTenant;