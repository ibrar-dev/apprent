import React, {Component, Fragment} from 'react';
import {Row, Col, ModalHeader, ModalBody, Table, ModalFooter, Collapse, Button} from 'reactstrap';
import {connect} from "react-redux";
import actions from '../../../actions';
import Checkbox from "../../../../../components/fancyCheck/index";
import TodaysTour from './todaysTour'
import Pagination from "../../../../../components/simplePagination";

class TodaysTours extends Component {
  state = {
    selectedPartsIDs: []
  }

  headers = {columns: [
      {label: 'Name', min: true},
      {label: 'Property', min: true},
      {label: 'Time', min: true}
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
        Todays Tours
        <br/>
        <small>Below are todays tours</small>
      </ModalHeader>
      <ModalBody>
        <Pagination
            title="Todays Tours"
            collection={info}
            component={TodaysTour}
            headers={this.headers}
            filters={this._filters()}
            field="tour"
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
  return {info: propertyReport.resident_info.todays_showings};
})(TodaysTours);