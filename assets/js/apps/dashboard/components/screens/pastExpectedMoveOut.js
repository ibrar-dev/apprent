import React, {Component, Fragment} from 'react';
import {ModalHeader, ModalBody, Table} from 'reactstrap';
import {connect} from "react-redux";
import moment from 'moment';

class NoChargeLeases extends Component {
  state = {}

  residentToDisplay(lease) {
    const ten = lease.tenants[0];
    return <a href={`/tenants/${ten.id}`} target="_blank" >{ten.last_name}</a>
  }

  render() {
    const {info} = this.props;
    return <Fragment>
      <ModalHeader>
        Leases with past move out dates
        <br/>
        <small>Below are the residents that have stated they will move out but have not yet moved out.</small>
      </ModalHeader>
      <ModalBody>
        <Table>
          <thead>
          <tr>
            <th>Unit</th>
            <th>Lease End</th>
            <th>Expected Move Out</th>
            <th>Days Overdue</th>
            <th>Resident</th>
          </tr>
          </thead>
          <tbody>
          {info.map(l => {
            return <tr key={l.id}>
              <th>{l.unit}</th>
              <td>{l.end_date}</td>
              <td>{l.move_out_date}</td>
              <td>{moment().diff(moment(l.move_out_date), 'days')}</td>
              <td>{this.residentToDisplay(l)}</td>
            </tr>
          })}
          </tbody>
        </Table>
      </ModalBody>
    </Fragment>
  }
}


export default connect(({propertyReport}) => {
  return {info: propertyReport.alerts.past_expected_move_out};
})(NoChargeLeases);