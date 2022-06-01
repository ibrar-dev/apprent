import React, {Component, Fragment} from 'react';
import {Row, Col, ModalHeader, ModalBody, Table, ModalFooter, Collapse, Button} from 'reactstrap';
import {connect} from "react-redux";
import actions from '../../../actions';
import Checkbox from "../../../../../components/fancyCheck/index";
import confirmation from '../../../../../components/confirmationModal/index';
import ExpiredLease from './expiredLease'
import Pagination from "../../../../../components/simplePagination";

class ExpiringLeases extends Component {
  state = {
    selectedPartsIDs: []
  }

  headers = {columns: [
      {label: 'Name', min: true},
      {label: 'Property', min: true},
      {label: 'Unit', min: true},
      {label: 'Floor Plan'},
      {label: 'Current Rate', min: true},
      {label: 'End Date', sort: 'name'},
    ], style: {color: '#7d7d7d'}};

  _filters() {

  }

  selectPart(id) {
    let selectedPartsIDs = this.state.selectedPartsIDs;
    selectedPartsIDs.includes(id) ? selectedPartsIDs.splice(selectedPartsIDs.indexOf(id), 1) : selectedPartsIDs.push(id);
    this.setState({...this.state, selectedPartsIDs: selectedPartsIDs});
  }

  render() {
    const {info} = this.props;
    const {selectedPartsIDs} = this.state;
    return <Fragment>
      <ModalHeader>
        Expiring Leases
        <br/>
        <small>Below are leases expiring soon.</small>
      </ModalHeader>
      <ModalBody>
        <Pagination
            title="Expiring Leases"
            collection={info}
            component={ExpiredLease}
            headers={this.headers}
            filters={this._filters()}
            field="lease"
            hover={true}
        />
      </ModalBody>
      <Collapse isOpen={selectedPartsIDs.length >= 1}>
        <ModalFooter>
          <Button outline color="success" >Update Parts</Button>
        </ModalFooter>
      </Collapse>
    </Fragment>
  }
}


export default connect(({propertyReport}) => {
  return {info: propertyReport.resident_info.expiring_leases};
})(ExpiringLeases);