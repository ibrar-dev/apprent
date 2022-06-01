import React, {Component, Fragment} from 'react';
import {ModalHeader, ModalBody, ModalFooter, Collapse, Button} from 'reactstrap';
import {connect} from "react-redux";
import AvailableUnit from '../../screens/availableUnits/availableUnit';
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
    const {preleasedUnits} = this.props;
    return <Fragment>
      <ModalHeader>
        Pre-Leased Units
        <br/>
        <small>Below are the pre-leased units.</small>
      </ModalHeader>
      <ModalBody>
        <Pagination
          title="Pre-Leased Units"
          collection={preleasedUnits}
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
  return {preleasedUnits: propertyReport.property_info.preleased_units};
})(AvailableUnits);