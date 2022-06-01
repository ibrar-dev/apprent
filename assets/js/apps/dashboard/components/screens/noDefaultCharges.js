import React, {Component, Fragment} from 'react';
import {ModalHeader, ModalBody, Table} from 'reactstrap';
import {connect} from "react-redux";

class NoDefaultCharges extends Component {
  state = {}



  render() {
    const {info} = this.props;
    console.log(info)
    return <Fragment>
      <ModalHeader>
        FloorPlans that have no Default Lease Charges
        <br/>
        <small>Below are all the floor plans that have no Default Lease Charges, go <a href="/features">HERE</a> to edit the floor plans.</small>
      </ModalHeader>
      <ModalBody>
        <Table>
          <thead>
          <tr>
            <th>Property</th>
            <th>FloorPlan</th>
            <th>Units</th>
          </tr>
          </thead>
          <tbody>
          {info.map(f => {
            return <tr key={f.id}>
              <td>{f.property}</td>
              <td>{f.name}</td>
              <td>{f.units.length}</td>
            </tr>
          })}
          </tbody>
        </Table>
      </ModalBody>
    </Fragment>
  }
}


export default connect(({propertyReport}) => {
  return {info: propertyReport.alerts.floorplans_with_no_default_charges};
})(NoDefaultCharges);