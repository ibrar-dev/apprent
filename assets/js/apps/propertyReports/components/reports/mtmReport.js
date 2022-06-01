import React, {Component} from 'react';
import {connect} from 'react-redux';
import {Table, Badge} from 'reactstrap';
import moment from 'moment';

class MTM extends Component {
  state = {};

  getRentAmount(lease) {
    const rent = lease.bills.filter(b => b.account_id === 1)[0];
    return rent && rent.amount || "N/A"
  }

  leaseCharges(lease) {
    return lease.recent_charges.slice(0, 3).map(l => {
      return <React.Fragment key={l.id}>
        <span>{l.account}: <b>${l.amount}</b>: {moment(l.bill_date).format('MM/DD')}</span>
        <br/>
      </React.Fragment>
    })
  }

  render() {
    const {reportData} = this.props;
    return <Table className="mt-1" striped>
      <thead>
      <tr>
        <th>Resident</th>
        <th>Unit</th>
        <th>Lease End</th>
        <th>Months</th>
        <th>Rent Rate</th>
        <th>Recent Charges</th>
      </tr>
      </thead>
      <tbody>
      {reportData.length > 0 && reportData.map(l => {
        const monthChargeMade = !l.recent_charges.find(x => {
          return moment(x.bill_date).isSameOrAfter(moment().startOf('month'))
        });
        return <tr key={l.id}>
          <td>
            <div className="d-flex align-items-center">
              <ul className="list-unstyled mb-0 mr-2">
                {l.residents.map(r => {
                  return <li key={r.id} className="list-unstyled">
                    <a href={`/tenants/${r.id}`} target="_blank">
                      {r.first_name} {r.last_name}
                    </a>
                  </li>
                })}
              </ul>
              {monthChargeMade && <Badge color="danger" className="pb-1" pill>No Charge</Badge>}
            </div>
          </td>
          <td>{l.unit}</td>
          <td>{l.end_date}</td>
          <td>{moment(l.end_date).fromNow()}</td>
          <td>${this.getRentAmount(l)}</td>
          <td>{this.leaseCharges(l)}</td>
        </tr>
      })}
      </tbody>
    </Table>;
  }
}

export default connect(({property, reportData}) => {
  return {property, reportData}
})(MTM)
