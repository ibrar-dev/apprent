import React, {Component, Fragment} from 'react';
import {Row, Col, ModalHeader, ModalBody, Table, ModalFooter, Collapse, Button} from 'reactstrap';
import {connect} from "react-redux";
import actions from '../../actions';
import Checkbox from "../../../../components/fancyCheck";
import confirmation from '../../../../components/confirmationModal';
import moment from "moment";

class MoveIns extends Component {
  state = {
    selectedLeaseIDs: []
  }

  selectLease(id) {
    let selectedLeaseIDs = this.state.selectedLeaseIDs;
    selectedLeaseIDs.includes(id) ? selectedLeaseIDs.splice(selectedLeaseIDs.indexOf(id), 1) : selectedLeaseIDs.push(id);
    this.setState({...this.state, selectedLeaseIDs: selectedLeaseIDs});
  }

  moveInLeases() {
    const {selectedLeaseIDs} = this.state;
    confirmation(`Please confirm that you would like to set the Actual Move In date for ${selectedLeaseIDs.length >= 2 ? 'these leases.' : 'this lease.'} `).then(() => {
      actions.multipleLeases({lease_ids: selectedLeaseIDs, params: {actual_move_in: moment()}});
    });
  }

  render() {
    const {info} = this.props;
    const {selectedLeaseIDs} = this.state;
    return <Fragment>
      <ModalHeader>
        Todays Move Ins
        <br/>
        <small>Below are leases that have an expected Move In Date of today</small>
      </ModalHeader>
      <ModalBody>
        <Table>
          <thead>
            <tr>
              <th>Unit</th>
              <th>Lease Start</th>
              <th>Expected Move In</th>
              <th>Resident</th>
              <th>Move In</th>
            </tr>
          </thead>
          <tbody>
          {info.map(l => {
            return <tr key={l.id}>
              <th>{l.unit.number}</th>
              <td>{l.start_date}</td>
              <td>{l.expected_move_in}</td>
              <td>{l.tenant.name}</td>
              <td className="align-middle text-center">
                <Checkbox checked={selectedLeaseIDs.includes(l.id)} inline
                          style={{marginBottom: -4}}
                          onChange={this.selectLease.bind(this, l.id)} color='primary'/>
              </td>
            </tr>
          })}
          </tbody>
        </Table>
      </ModalBody>
      <Collapse isOpen={selectedLeaseIDs.length >= 1}>
        <ModalFooter>
          <Button outline color="success" onClick={this.moveInLeases.bind(this)}>Move In Resident{selectedLeaseIDs.length >= 2 ? 's' : null}</Button>
        </ModalFooter>
      </Collapse>
    </Fragment>
  }
}


export default connect(({propertyReport}) => {
  return {info: propertyReport.resident_info.move_ins};
})(MoveIns);