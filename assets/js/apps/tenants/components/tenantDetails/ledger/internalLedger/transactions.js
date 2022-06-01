import React from 'react';
import moment from 'moment';
import {CardBody, Table} from 'reactstrap';
import Charge from './charge';
import Payment from './payment';

class Transactions extends React.Component {

  transactionsToDisplay(t, total) {
    const {isLocked, startDate, endDate} = this.props;
    const start = startDate ? moment(startDate) <= moment(t.bill_date || t.inserted_at || t.date) : false;
    const end = endDate ? moment(endDate) >= moment(t.bill_date || t.inserted_at || t.date) : false;
    if ((!endDate && !startDate) || (!endDate && start) || (!startDate && end) || moment(t.bill_date || t.inserted_at || t.date).isBetween(startDate, endDate, null, '[]')) {
      if (t.isPayment) return <Payment key={`p${t.id}`} payment={t} total={total} isLocked={isLocked}/>;
      return <Charge key={t.id} charge={t} total={total} isLocked={isLocked}/>
    }
  }

  render() {
    const {transactions, isLocked} = this.props;
    let total = 0;
    return <CardBody className="p-0">
      <Table className={`data-table m-0${isLocked ? ' text-secondary' : ''}`}>
        <thead>
        <tr>
          <th className="min-width"/>
          <th className="min-width"/>
          <th className="min-width">Date</th>
          <th className="min-width nowrap">Post Month</th>
          <th>Account</th>
          <th>Charge</th>
          <th>Payment</th>
          <th>Balance</th>
          <th style={{width: 130}}>Notes</th>
          <th>Admin</th>
        </tr>
        </thead>
        <tbody>
        {transactions && transactions.map(t => {
          if (t.status !== 'voided') {
            total = total + (t.amount * (t.isPayment ? -1 : 1));
          }
          return this.transactionsToDisplay(t, total)
        })}
        </tbody>
      </Table>
    </CardBody>;
  }
}

export default Transactions;