import React from 'react';
import {CardBody, CardHeader, Table} from "reactstrap";
import moment from "moment";
import Payment from "./payment";
import Refund from "./refund";
import DateRangePicker from "../../../components/dateRangePicker";

class Applicant extends React.Component {
  state = {};

  constructor(props) {
    super(props);
    const {transactions} = props;
    if (transactions.length > 0) {
      const startDate = moment(transactions[0].date).startOf('day');
      const endDate = moment(transactions[transactions.length - 1].date).endOf('day');
      this.state = {startDate, endDate, transactionType: 'all'};
    }
  }

  transactionsToDisplay(t) {
    const {startDate, endDate} = this.state;
    const start = startDate ? moment(startDate) <= moment(t.date) : false;
    const end = endDate ? moment(endDate) >= moment(t.date) : false;
    if ((!endDate && !startDate) || (!endDate && start) || (!startDate && end) || moment(t.date).isBetween(startDate, endDate, null, '[]')) {
      if (t.type === 'refund') return <Refund key={`r${t.id}`} refund={t}/>;
      return <Payment key={`p${t.id}`} payment={t}/>;
    }
  }

  changeDates({startDate, endDate}) {
    const start = startDate ? moment(startDate) : null;
    if (startDate) start.startOf('day');
    const end = endDate ? moment(endDate) : null;
    if (endDate) end.endOf('day');
    const dates = {startDate: start, endDate: end};
    this.setState({...dates});
  }

  render() {
    const {transactions, applicants} = this.props;
    const {startDate, endDate} = this.state;
    let total = 0;
    return <CardBody className="p-0">
      <CardHeader className="d-flex justify-content-between align-items-center pr-2">
        <div className="d-flex">
          {applicants.map((a, i) => <span key={a.id}>{a.full_name}{i < (applicants.length - 1) ? ', ' : ''}</span>)}
        </div>
        <div className="d-flex">
          <div className="d-inline-block">
            <DateRangePicker clearField={true} startDate={startDate} endDate={endDate}
                             onDatesChange={this.changeDates.bind(this)}/>
          </div>
        </div>
      </CardHeader>
      <Table className={`data-table m-0`}>
        <thead>
        <tr>
          <th className="min-width"/>
          <th className="min-width"/>
          <th className="min-width">Date</th>
          <th className="min-width nowrap">Post Month</th>
          <th>Description</th>
          <th>Payment</th>
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

export default Applicant;