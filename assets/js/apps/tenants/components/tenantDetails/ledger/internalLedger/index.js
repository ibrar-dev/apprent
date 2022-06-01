import React, {useState} from 'react';
import Transactions from './transactions'
import transactionsFromTenant from './transactionsFromTenant';
import {Card, CardBody, CardHeader} from "reactstrap";
import ledgerSwitch from "../ledgerSwitch";
import header from './header';
import moment from "moment";

const defaultDates = (transactions) => {
  const startDate = moment.unix(transactions[0].ts).startOf('day');
  const endDate = moment.unix(transactions[transactions.length - 1].ts).endOf('day');
  return {startDate, endDate}
};

function internalLedger(tenant, activeLease, setActiveLease) {
  const {ledgers} = transactionsFromTenant(tenant);

  const transactions = ledgers[activeLease.unit.number];
  const [{startDate, endDate}, setDates] = useState(defaultDates(transactions));
  return <Card className="ml-3">
    <CardHeader className="d-flex justify-content-between align-items-center pr-2">
      {ledgerSwitch(tenant.leases, activeLease, setActiveLease)}
      {header(tenant, activeLease, {startDate, endDate}, setDates)}
    </CardHeader>
    <CardBody>
      <Transactions isLocked={activeLease.closed} transactions={transactions} startDate={startDate} endDate={endDate}/>
    </CardBody>
  </Card>
}

export default internalLedger; 