import React, {Component, Fragment} from 'react';
import {Row, Col, ModalHeader, ModalBody, Table, ModalFooter, Collapse, Button} from 'reactstrap';
import {connect} from "react-redux";
import actions from '../../actions';
import Checkbox from "../../../../components/fancyCheck";
import confirmation from '../../../../components/confirmationModal';

class PartsPending extends Component {
  state = {
    selectedParts: [],
    selectedPartsUpdated: []
  }

  selectPart(part) {
    var updatedPart;
    switch (part.status) {
      case "pending":
        updatedPart = {status:'ordered', id: part.id}
        break;
      case "ordered":
        updatedPart = {status:'delivered', id: part.id}
        break;
      default:
        updatedPart = {status:'pending', id: part.id}
    }
    let selectedParts = this.state.selectedParts;
    let selectedPartsUpdated = this.state.selectedPartsUpdated;
    selectedParts.includes(part) ? selectedParts.splice(selectedParts.indexOf(part), 1) && selectedPartsUpdated.splice(selectedPartsUpdated.indexOf(part), 1)  : selectedParts.push(part) && selectedPartsUpdated.push(updatedPart);
    this.setState({...this.state, selectedParts: selectedParts});
  }

  updateParts() {
    const {toggle} = this.props
    const {selectedPartsUpdated} = this.state;
    actions.updateParts(selectedPartsUpdated, this.props.orderId).then(toggle)

  }
  // moveInLeases() {
  //   const {selectedLeaseIDs} = this.state;
  //   confirmation(`Please confirm that you would like to set the Actual Move In date for ${selectedLeaseIDs.length >= 2 ? 'these leases.' : 'this lease.'} `).then(() => {
  //     actions.multipleLeases({lease_ids: selectedLeaseIDs, params: {actual_move_in: moment()}});
  //   });
  // }

  render() {
    const {info} = this.props;
    const {selectedParts} = this.state;
    return <Fragment>
      <ModalHeader>
        Parts Pending
        <br/>
        <small>Below are parts that are in pending or ordered status.</small>
      </ModalHeader>
      <ModalBody>
        <Table>
          <thead>
          <tr>
            <th>Name</th>
            <th>Status</th>
            <th>Property</th>
            <th>Unit</th>
            <th></th>
          </tr>
          </thead>
          <tbody>
          {info.map(p => {
            return <tr key={p.id}>
              <td>{p.name}</td>
              <td>{p.status}</td>
              <td>{p.unit}</td>
              <td>{p.property}</td>
              <td className="align-middle text-center">
                <Checkbox checked={selectedParts.includes(p)} inline
                          style={{marginBottom: -4}}
                          onChange={this.selectPart.bind(this, p)} color='primary'/>
              </td>
            </tr>
          })}
          </tbody>
        </Table>
      </ModalBody>
      <Collapse isOpen={selectedParts.length >= 1}>
        <ModalFooter>
          <Button outline color="success" onClick={this.updateParts.bind(this)}>Update Parts</Button>
        </ModalFooter>
      </Collapse>
    </Fragment>
  }
}


export default connect(({propertyReport}) => {
  return {info: propertyReport.maintenance_info.pending_and_ordered_parts};
})(PartsPending);