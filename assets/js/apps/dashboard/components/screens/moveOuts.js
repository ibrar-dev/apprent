import React, {Component, Fragment} from 'react';
import {Row, Col, ModalHeader, ModalBody, Table, ModalFooter, Collapse, Button} from 'reactstrap';
import {connect} from "react-redux";
import moment from 'moment';
import actions from '../../actions';
import Checkbox from "../../../../components/fancyCheck";
import confirmation from '../../../../components/confirmationModal';

class MoveOuts extends Component {
  state = {
    selectedLeaseIDs: []
  }

  selectLease(id) {
    let selectedLeaseIDs = this.state.selectedLeaseIDs;
    selectedLeaseIDs.includes(id) ? selectedLeaseIDs.splice(selectedLeaseIDs.indexOf(id), 1) : selectedLeaseIDs.push(id);
    this.setState({...this.state, selectedLeaseIDs: selectedLeaseIDs});
  }

  moveOutLeases() {
    const {selectedLeaseIDs} = this.state;
    confirmation(`Please confirm that you would like to set the Actual Move Out date for ${selectedLeaseIDs.length >= 2 ? 'these leases.' : 'this lease.'} `).then(() => {
      actions.multipleLeases({lease_ids: selectedLeaseIDs, params: {actual_move_out: moment()}});
    });
  }

  render() {
    const {info} = this.props;
    const {selectedLeaseIDs} = this.state;
    return <Fragment>
      <ModalHeader>
        Todays Move Outs
        <br/>
        <small>Below are leases that have a move out date in the past but no set Actual Move Out</small>
      </ModalHeader>
      <ModalBody>
        <Table>
          <thead>
          <tr>
            <th>Unit</th>
            <td>Lease End</td>
            <td>Expected Move Out</td>
            <th>Resident</th>
            <th>Move Out</th>
          </tr>
          </thead>
          <tbody>
          {info.map(l => {
            return <tr key={l.id}>
              <th>{l.unit.number}</th>
              <td>{l.end_date}</td>
              <td>{l.move_out_date}</td>
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
          <Button outline color="success" onClick={this.moveOutLeases.bind(this)}>Move Out Resident{selectedLeaseIDs.length >= 2 ? 's' : null}</Button>
        </ModalFooter>
      </Collapse>
    </Fragment>
  }
}


export default connect(({propertyReport}) => {
  return {info: propertyReport.resident_info.move_outs};
})(MoveOuts);