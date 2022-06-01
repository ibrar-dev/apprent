import React, {Component} from 'react';
import {connect} from 'react-redux';
import {Row, Col} from 'reactstrap';
import moment from 'moment';

class BasicInfo extends Component {
  state = {open: false};

  getLeaseLength() {
    const {lease: {approval_params: {start_date, end_date}}} = this.props;
    return moment(end_date).diff(moment(start_date), 'months')
  }

  getUnitInfo() {
    const {lease: {approval_params: {unit_id}}} = this.props;
    // console.log(unit_id);
    // console.log(this.props.units);
    // console.log(this.props.units.find(u => u.id === 149968));
    return this.props.units.find(u => u.id === unit_id);
  }

  calculateProratedRent() {
    const {lease: {approval_params: {start_date}}} = this.props;
    const rent = this.getTotalRent();
    const days = moment(start_date).daysInMonth();
    const occupiedDays = (days - parseInt(moment(start_date).format("D")) + 1);
    return ((rent / days) * occupiedDays).toFixed(2)
  }

  getTotalRent() {
    const {lease: {approval_params: {charges}}} = this.props;
    return charges.reduce((total, c) => parseInt(c.amount) + total, 0)
  }

  render() {
    const {lease} = this.props;
    const multi = lease.persons.length >= 2;
    return <Row>
      <Col>
        <p>This is a <b>{this.getLeaseLength()}</b> month lease for Unit <b>{this.getUnitInfo().number}</b>. The
          monthly Total Rent is currently set to $<b>{this.getTotalRent()}.</b></p>
        <p>The prorated rent of $<b>{this.calculateProratedRent()}</b> will be due when the lease starts,
          on <b>{lease.approval_params.start_date}</b></p>
        <p>There {multi ? 'are' : 'is'} currently {lease.persons.length} {multi ? 'people' : 'person'} on
          the lease.</p>
      </Col>
    </Row>;
  }
}

export default connect(({lease, units}) => {
  return {lease, units}
})(BasicInfo);