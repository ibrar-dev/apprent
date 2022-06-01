import React, {Component} from 'react';
import {connect} from 'react-redux';
import {Row, Input} from 'reactstrap';
import Pagination from "../../../../components/pagination";
import moment from 'moment';
import {toCurr} from "../../../../utils";

const headers = [
  {label: 'Unit', sort: (a,b) => a.unit.number - b.unit.number},
  {label: 'Tenant Name'},
  {label: 'Tenant Email'},
  {label: 'Deposit'},
  {label: 'Rent', sort: (a,b) => a.rent - b.rent},
  {label: 'Start Date', sort: (a,b) => moment(a.start_date) < moment(b.start_date) ? 1 : -1},
  {label: 'End Date', sort: (a,b) => moment(a.end_date) < moment(b.end_date) ? 1 : -1},
  {label: 'Moved In', sort: (a,b) => moment(a.actual_move_in) < moment(b.actual_move_in) ? 1 : -1},
  {label: 'Moved Out', sort: (a,b) => moment(a.actual_move_out) < moment(b.actual_move_out) ? 1 : -1},
  {label: 'Status'}
];

class ResidentRow extends Component {

  status() {
    const {tenant_row: {lease, eviction}} = this.props;
    const today = moment().format("YYYY-MM-DD");
    const isCurrent = (moment().isBetween(moment(lease.start_date), moment(lease.end_date)) || (!lease.actual_move_out && !lease.renewal));

    if (moment(lease.start_date).isAfter(today)) {
      return 'Future';
    } else if (eviction && lease.actual_move_out) {
      return 'Evicted';
    } else if (eviction) {
      return 'Under Eviction';
    } else if (lease.actual_move_out) {
      return 'Moved Out';
    } else if (lease.renewal) {
      return 'Renewal'
    } else if (isCurrent) {
      return 'Current Lease';
    } else {
      return 'Month to Month';
    }
  }

  render() {
    const {tenant_row: {lease, rent, unit, tenants, deposit}} = this.props;
    return <tr key={lease.id}>
      <td>{unit.number}</td>
      <td>{tenants.map(t => <Row>{t.first_name} {t.last_name}</Row>)}</td>
      <td>{tenants.map(t => <Row>{t.email}</Row>)}</td>
      <td>{toCurr(deposit)}</td>
      <td>{toCurr(rent)}</td>
      <td>{lease.start_date}</td>
      <td>{lease.end_date}</td>
      <td>{lease.actual_move_in}</td>
      <td>{lease.actual_move_out}</td>
      <td>{lease && this.status()}</td>
    </tr>;
  }
}

class ResidentDirectory extends Component {
  state = {};

  changeFilter(e) {
    this.setState({filterVal: e.target.value});
  }

  _filters() {
    return <Input value={this.state.filterVal} onChange={this.changeFilter.bind(this)}/>
  }

  filtered() {
    const {residentsData} = this.props;
    const {filterVal} = this.state;
    return residentsData.filter(({unit, tenants}) => {
      if (!filterVal) return true;
      if (unit.number.includes(filterVal)) return true;
      return tenants.some(t => `${t.first_name} ${t.last_name}`.toLowerCase().includes(filterVal.toLowerCase()));
    })
  }

  render() {
    return <Pagination
      field="tenant_row"
      title="Resident Directory"
      component={ResidentRow}
      collection={this.filtered()}
      headers={headers}
      filters={this._filters()}
    />
  }
}

export default connect(({residentsData}) => {
  return {residentsData};
})(ResidentDirectory)
