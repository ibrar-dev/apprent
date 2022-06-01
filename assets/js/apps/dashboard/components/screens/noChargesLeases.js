import React, {Component, Fragment} from 'react';
import {ModalHeader, ModalBody, Table, ModalFooter, Collapse, Button} from 'reactstrap';
import {connect} from "react-redux";

import moment from "moment";

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
        Leases With No Charges
        <br/>
        <small>Below are leases that do not have any charges</small>
      </ModalHeader>
      <ModalBody>
        <Table>
          <thead>
          <tr>
            <th>Unit</th>
            <th>Lease Start</th>
            <th>Expected Move In</th>
            <th>Actual Move In</th>
            <th>Resident</th>
          </tr>
          </thead>
          <tbody>
          {info.map(l => {
            return <tr key={l.id}>
              <th>{l.unit}</th>
              <td>{l.start_date}</td>
              <td>{l.expected_move_in}</td>
              <td>{l.actual_move_in}</td>
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
  return {info: propertyReport.alerts.no_charge_leases};
})(NoChargeLeases);