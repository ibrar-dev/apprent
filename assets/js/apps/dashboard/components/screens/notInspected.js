import React, {Component} from 'react';
import {Modal, ModalHeader, ModalBody, Table, Input} from 'reactstrap';
import {connect} from "react-redux";
import Pagination from '../../../../components/simplePagination';
import moment from 'moment';

class Unit extends Component {
  calculateDays(lease_end) {
    return moment(moment()).diff(lease_end, 'days');
  }
  render() {
    const {unit} = this.props;
    return <tr>
      <td>{unit.property}</td>
      <td>{unit.unit}</td>
      <td>{unit.lease_end}</td>
      <td>{unit.move_out}</td>
      <td>{this.calculateDays(unit.lease_end)} Days</td>
    </tr>
  }
}

const headers = {
  columns: [
    {label: 'Property'},
    {label: 'Unit', min: true},
    {label: 'Lease End'},
    {label: 'Move Out'},
    {label: 'Days'},
  ],
  style: {color: '#7d7d7d'}
};

class NotInspected extends Component {
  state = {
    filter: ''
  }

  changeFilter({target: {value}}) {
    this.setState({...this.state, filter: value})
  }

  filters() {
      return <Input value={this.state.filter} placeholder="Property or Unit" onChange={this.changeFilter.bind(this)} />
  }

  filterUnits() {
    const {units} = this.props;
    const {filter} = this.state;
    const tester = new RegExp(filter, 'i');
    return units.filter(u => tester.test(u.property) || tester.test(u.unit));
  }

  render() {
    const {units, toggle} = this.props;
    return <Modal size="lg" isOpen={true} toggle={toggle}>
      <ModalHeader>Units That Need To Be Inspected</ModalHeader>
      {units && units.length && <ModalBody>
        <Pagination title="Units missing a card"
                    filters={this.filters()}
                    collection={this.filterUnits()}
                    component={Unit}
                    headers={headers}
                    field="unit"
                    hover={true}
        />
      </ModalBody>}
    </Modal>
  }
};

export default connect(({propertyReport}) => {
  return {units: propertyReport.maintenance_info.not_yet_inspected_units};
})(NotInspected);