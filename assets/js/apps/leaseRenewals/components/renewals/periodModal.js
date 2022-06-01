import React from 'react';
import {connect} from 'react-redux';
import {Modal, ModalHeader, ModalBody, ModalFooter, Button, Col, Row} from 'reactstrap';
import moment from "moment";
import isInclusivelyBeforeDay from "react-dates/lib/utils/isInclusivelyBeforeDay";
import NewPackage from './newPackage';
import DateRangePicker from '../../../../components/dateRangePicker';
import actions from "../../actions";

const calculateDays = (date) => {
  return moment(date).diff(moment(), 'days');
};

const defaultPackages = [
  {min: 7, max: 7, base: 'Current Rent', amount: null, dollar: false, index: 0},
  {min: 8, max: 9, base: 'Current Rent', amount: null, dollar: false, index: 1},
  {min: 10, max: 11, base: 'Current Rent', amount: null, dollar: false, index: 2},
  {min: 12, max: 14, base: 'Current Rent', amount: null, dollar: false, index: 3}
];

class PeriodModal extends React.Component {
  state = {packages: [...defaultPackages], ...this.props.period};

  changeDates({startDate, endDate}) {
    if (startDate.isAfter(endDate)) endDate = startDate.clone().add(1, 'days');
    actions.checkValidDates(startDate.format("YYYY-MM-DD"), endDate.format("YYYY-MM-DD"));
    this.setState({end_date: endDate, start_date: startDate});
  }

  changePackage(index, {target: {name, value}}) {
    const {packages} = this.state;
    packages[index] = {...packages[index], [name]: name === 'dollar' ? value === '1' : value};
    this.setState({packages});
  }

  remove(index) {
    const {packages} = this.state;
    packages.splice(index, 1);
    this.setState({packages: [...packages]});
  }

  valid() {
    const {start_date, end_date, packages} = this.state;
    return start_date && end_date && packages.every(p => p.min && p.max && p.amount && p.base);
  }

  addPackage() {
    const {packages} = this.state;
    const maxId = packages.reduce((max, p) => max < (p.id || p.index) ? (p.id || p.index) : max, 0);
    const newPackages = [...packages];
    newPackages.push({index: maxId + 1, base: 'Current Rent', dollar: false});
    this.setState({packages: newPackages});
  }

  save() {
    const {property, toggle} = this.props;
    const {start_date, end_date, packages, id} = this.state;
    const params = {property_id: property.id, start_date, end_date, packages};
    const promise = id ? actions.updatePeriod(id, {period: params}) : actions.savePeriod(params);
    promise.then(toggle);
  }

  render() {
    const {toggle, validation} = this.props;
    const {start_date, end_date, packages} = this.state;
    return <Modal isOpen={true} toggle={toggle} size="lg">
      <ModalHeader toggle={toggle}>New Renewal Period</ModalHeader>
      <ModalBody>
        <div className="d-flex justify-content-between">
          <DateRangePicker startDate={start_date} endDate={end_date}
                           onDatesChange={this.changeDates.bind(this)}
                           isOutsideRange={day => isInclusivelyBeforeDay(day, moment())}/>
          <Button outline color="success" onClick={this.addPackage.bind(this)}>
            <i className="fas fa-plus"/> Add Package
          </Button>
        </div>
        <div className="d-flex mt-1 align-items-center">
          <i
            className={`fas fa-${validation.validDates ? 'check text-success' : 'times text-danger'} ${validation.loading ? 'fa-spin' : ''}`}/>
          {start_date && end_date && <div className="small ml-1 mr-4">
            All Leases Ending in {calculateDays(start_date)} - {calculateDays(end_date)} days
          </div>}
          <div className="small ml-1">
            {validation.validDates ? `${validation.leases} leases will be eligible for these packages` : 'Not Valid Dates'}
          </div>
        </div>
        <Row className="d-flex justify-content-between align-items-center mt-2">
          <div className="pl-2" style={{width: 20}}/>
          <Col className="pr-0">
            <span>Package</span>
          </Col>
          <Col className="pr-0 text-center">
            <b>Minimum Term</b>
          </Col>
          <Col className="pr-0 text-center">
            <b>Maximum Term</b>
          </Col>
          <Col className="pr-0 text-center">
            <b>Amount</b>
          </Col>
          <Col className="pr-0 text-center">
            <b>Modifier</b>
          </Col>
          <Col className="text-center">
            <b>Base</b>
          </Col>
        </Row>
        {packages.map((p, i) => <NewPackage key={p.id || p.index} remove={this.remove.bind(this, i)} params={p}
                                            index={i} change={this.changePackage.bind(this, i)}/>)}
      </ModalBody>
      <ModalFooter>
        <Button disabled={!this.valid()} color="success" onClick={this.save.bind(this)}>
          Save
        </Button>
      </ModalFooter>
    </Modal>;
  }
}

export default connect(({validation, property}) => {
  return {validation, property};
})(PeriodModal);