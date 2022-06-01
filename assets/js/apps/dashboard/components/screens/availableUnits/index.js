import React, {Component, Fragment} from 'react';
import {ModalHeader, ModalBody, ModalFooter, Collapse, Button} from 'reactstrap';
import {connect} from "react-redux";
import AvailableUnit from './availableUnit'
import Pagination from "../../../../../components/simplePagination";

class AvailableUnits extends Component {
  state = {
    selectedPartsIDs: []
  };

  headers = {columns: [
      {label: 'Property', min: true},
      {label: 'Unit', min: true},
      {label: 'Status'}
    ], style: {color: '#7d7d7d'}};

  _filters() {

  }

  render() {
    const {availableUnits} = this.props;
    return <Fragment>
      <ModalHeader>
        Available Units
        <br/>
        <small>Below are available units.</small>
      </ModalHeader>
      <ModalBody>
        <Pagination
            title="Available Units"
            collection={availableUnits}
            component={AvailableUnit}
            headers={this.headers}
            filters={this._filters()}
            field="unit"
            hover={true}
        />
      </ModalBody>
    </Fragment>
  }
}


export default connect(({propertyReport}) => {
  return {availableUnits: propertyReport.property_info.available_units};
})(AvailableUnits);