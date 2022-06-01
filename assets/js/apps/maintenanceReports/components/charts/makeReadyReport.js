import React, {Component} from 'react';
import {connect} from "react-redux";
import {Row, Col, Card, ButtonGroup, Button, Modal, ModalHeader, ModalBody, Table} from "reactstrap";
import colors from "../../../usageDashboard/components/colors";
import Pagination from '../../../../components/pagination';
import moment from 'moment';

const headers = [
  {label: '', min: true},
  {label: 'Property', sort: 'name'},
  {label: 'Made Ready Units', sort: (p1, p2) => p1.units.length > p2.units.length ? 1 : -1},
  {label: 'Average Completion Time', sort: 'completion_time'}
];

class PropertyList extends Component {
  calculateDaysDiff(startDate, endDate) {
    return moment(moment(endDate)).diff(moment(startDate), 'days');
  }
  render () {
    const {property, toggle} = this.props;
    return <Modal isOpen={true} toggle={toggle} size="lg">
      <ModalHeader toggle={toggle}>{property.name}</ModalHeader>
      <ModalBody>
        <Row>
          <Col>
            <Row className="border-bottom border-dark">
              <Col><b>Unit</b></Col>
              <Col><b>Move Out Date</b></Col>
              <Col><b>Inspection Date</b></Col>
              <Col><b>Completion Date</b></Col>
              <Col><b>Punch Tech</b></Col>
            </Row>
            {property.units.map(u => {
              return <Row key={u.id} className="mt-1 border-top-0 border border-light">
                <Col>{u.unit}</Col>
                <Col>{u.move_out_date}</Col>
                <Col className="d-inline-flex flex-column"><span>{moment(u.inserted_at).format('YYYY-MM-DD')}</span><b>{this.calculateDaysDiff(u.move_out_date, u.inserted_at)}{" "}Days</b></Col>
                <Col className="d-inline-flex flex-column"><span>{u.completed_at}</span><b>{this.calculateDaysDiff(u.inserted_at, u.completed_at)}{" "}Days</b></Col>
                <Col>{u.punch_tech || 'N/A'}</Col>
              </Row>
            })}
          </Col>
        </Row>
      </ModalBody>
    </Modal>
  }
}

class BoringComponent extends Component {
  displayType() {
    const {property, display} = this.props;
    switch (display) {
      case 'days':
        return moment.duration(property.completion_time, 'seconds').asDays().toFixed(2);
        break;
      case 'hours':
        return moment.duration(property.completion_time, 'seconds').asHours().toFixed(2);
        break;
      case 'weeks':
        return moment.duration(property.completion_time, 'seconds').asWeeks().toFixed(2);
        break;
      default:
        return moment.duration(property.completion_time, 'seconds').humanize();
        break;
    }
  }
  render() {
    const {property, display, setOpenProperty} = this.props;
    return <tr onClick={setOpenProperty.bind(this, property)}>
      <td><img style={{maxHeight: 35}} src={property.icon} alt=""/></td>
      <td>{property.name}</td>
      <td>{property.units.length}</td>
      <td>{property.completion_time ? <React.Fragment>{this.displayType()} {display !== "humanize" ? display : ''}</React.Fragment> : '0'}</td>
    </tr>
  }
}

class MakeReadyReport extends Component {
  state = {
    suppressZeros: false,
    boringView: false,
    display: 'humanize'
  }

  displayType(property) {
    const {display} = this.state;
    switch (display) {
      case 'days':
        return moment.duration(property.completion_time, 'seconds').asDays().toFixed(2);
        break;
      case 'hours':
        return moment.duration(property.completion_time, 'seconds').asHours().toFixed(2);
        break;
      case 'weeks':
        return moment.duration(property.completion_time, 'seconds').asWeeks().toFixed(2);
        break;
      default:
        return moment.duration(property.completion_time, 'seconds').humanize();
        break;
    }
  }

  switchDisplay(display) {
    this.setState({...this.state, display: display})
  }

  toggle(type) {
    this.setState({...this.state, [type]: !this.state[type]})
  }

  propertiesToDisplay() {
    const {reportData} = this.props;
    const {suppressZeros} = this.state;
    return reportData.filter(p => {
      if (suppressZeros && p.units.length <= 0) return;
      return p;
    })
  }

  setOpenProperty(property) {
    this.setState({...this.state, openProperty: property})
  }

  render() {
    const {reportData} = this.props;
    const {boringView, suppressZeros, display, openProperty} = this.state;
    return <Row className="mt-3">
      <Col>
        <Row className="d-flex align-items-start">
          <Col className="d-flex justify-content-between">
            <ButtonGroup>
              <Button outline color="info" active={!boringView} onClick={this.toggle.bind(this, 'boringView')}>Cool View</Button>
              <Button outline color="info" active={boringView} onClick={this.toggle.bind(this, 'boringView')}>Boring View</Button>
            </ButtonGroup>
            <ButtonGroup>
              <Button outline color="info" active={suppressZeros} onClick={this.toggle.bind(this, 'suppressZeros')}>{suppressZeros ? 'Zeros are oppressed!' : 'Oppress the Zeros!'}</Button>
              <Button outline color="info" active={!suppressZeros} onClick={this.toggle.bind(this, 'suppressZeros')}>{!suppressZeros ? 'Zeros are free!' : 'Free the Zeros!'}</Button>
            </ButtonGroup>
          </Col>
          <Col>
            <ButtonGroup>
              <Button outline color="info" active={display === 'humanize'} onClick={this.switchDisplay.bind(this, 'humanize')}>Readable</Button>
              <Button outline color="info" active={display === 'hours'} onClick={this.switchDisplay.bind(this, 'hours')}>Hours</Button>
              <Button outline color="info" active={display === 'days'} onClick={this.switchDisplay.bind(this, 'days')}>Days</Button>
              <Button outline color="info" active={display === 'weeks'} onClick={this.switchDisplay.bind(this, 'weeks')}>Weeks</Button>
            </ButtonGroup>
          </Col>
        </Row>
        {boringView && <Row className="mt-1">
          <Col sm={12} className="">
            <Pagination collection={this.propertiesToDisplay()}
                        headers={headers}
                        field="property"
                        additionalProps={{display: display, setOpenProperty: this.setOpenProperty.bind(this)}}
                        component={BoringComponent} />
          </Col>
        </Row>}
        <Row className="mt-1">
          {reportData.length && this.propertiesToDisplay().map((p, i) => {
            const col = colors(i, reportData.length);
            return <Col sm={3} key={p.id}>
              <Card onClick={this.setOpenProperty.bind(this, p)} body style={{backgroundColor: col.replace(/, .*\)/, ',0.5)'), borderColor: col}} className="d-flex justify-content-between">
                <span className="d-flex justify-content-between">
                  <Col>
                    <span>
                      {p.icon && <img src={p.icon} style={{maxHeight: 35}} alt=""/>}
                      <b>{"   "}{p.name}</b>
                    </span>
                  </Col>
                  <Col className="d-flex flex-column align-items-end">
                    <span>Total Units Made Ready: {p.units.length}</span>
                    <span>Avg Completion: {p.completion_time && <React.Fragment>{this.displayType(p)} {display !== "humanize" ? display : ''}</React.Fragment>}</span>
                  </Col>
                </span>
              </Card>
            </Col>
          })}
        </Row>
      </Col>
      {openProperty && <PropertyList property={openProperty} toggle={this.setOpenProperty.bind(this, null)}/>}
    </Row>
  }
}

export default connect(({reportData}) => {
  return {reportData}
})(MakeReadyReport);
