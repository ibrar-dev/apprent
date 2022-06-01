import React, {Component} from 'react';
import {Row, Col, Card, ButtonGroup, Button, Modal, ModalHeader, ModalBody, Collapse, ListGroup, ListGroupItem} from "reactstrap";
import {connect} from "react-redux";
import colors from "../../../usageDashboard/components/colors";
import Pagination from '../../../../components/pagination';

const headers = [
  {label: '', min: true},
  {label: 'Property'},
  {label: 'Open Orders', sort: 'open_orders'},
  {label: 'Not Ready Units', sort: 'not_ready_units'},
  {label: 'Not Inspected Units', sort: 'not_inspected_units'}
];

class DetailedModal extends Component {
  state = {
    inspected: false,
    notInspected: false
  }

  expand(type) {
    this.setState({...this.state, [type]: !this.state[type]})
  }

  render() {
    const {property, toggle} = this.props;
    const {inspected, notInspected} = this.state;
    return <Modal isOpen={true} toggle={toggle}>
      <ModalHeader toggle={toggle}>Maintenance Report for {property.property.name}</ModalHeader>
      <ModalBody>
        <ListGroup>
          <ListGroupItem onClick={this.expand.bind(this, "inspected")} className="d-flex justify-content-between">
            <span>Not Ready Units</span>
            <span>{property.not_ready_units.length}</span>
          </ListGroupItem>
          <Collapse isOpen={inspected}>
            <ListGroupItem>
              <ListGroup>
                {property.not_ready_units && property.not_ready_units.length && property.not_ready_units.map(u => {
                  return <ListGroupItem key={u.lease_id} className="d-flex justify-content-between">
                    <span>Unit {u.unit}</span>
                    <span>Moved Out: {u.move_out}</span>
                  </ListGroupItem>
                })}
              </ListGroup>
            </ListGroupItem>
          </Collapse>
          <ListGroupItem onClick={this.expand.bind(this, "notInspected")} className="d-flex justify-content-between">
            <span>Not Inspected Units</span>
            <span>{property.not_inspected_units.length}</span>
          </ListGroupItem>
          <Collapse isOpen={notInspected}>
            <ListGroupItem>
              <ListGroup>
                {property.not_inspected_units && property.not_inspected_units.length && property.not_inspected_units.map(u => {
                  return <ListGroupItem key={u.id} className="d-flex justify-content-between">
                    <span>Unit {u.unit}</span>
                    <span>Moved Out: {u.move_out}</span>
                  </ListGroupItem>
                })}
              </ListGroup>
            </ListGroupItem>
          </Collapse>
        </ListGroup>
      </ModalBody>
    </Modal>
  }
}

class BoringComponent extends Component {
  render() {
    const {property, setProperty} = this.props;
    return <tr onClick={setProperty.bind(this, property)}>
      <td><img style={{maxHeight: 35}} src={property.property.icon} alt=""/></td>
      <td>{property.property.name}</td>
      <td>{property.open_orders}</td>
      <td>{property.not_ready_units.length}</td>
      <td>{property.not_inspected_units.length}</td>
    </tr>
  }
}

class KatsReport extends Component {
  state = {
    suppressZeros: false,
    boringView: false
  }

  toggle(type) {
    this.setState({...this.state, [type]: !this.state[type]})
  }

  propertiesToDisplay() {
    const {katsReport} = this.props;
    const {suppressZeros} = this.state;
    return katsReport.filter(p => {
      if (suppressZeros && (p.open_orders <= 0 || p.not_ready_units <= 0)) return;
      return p;
    })
  }

  setDetailedProperty(p) {
    this.setState({...this.state, detailed: p})
  }

  render() {
    const {katsReport} = this.props;
    const {boringView, suppressZeros, detailed} = this.state;
    return <Row className="mt-3">
      <Col>
        <Row className="d-flex align-items-start">
          <Col>
            <ButtonGroup>
              <Button outline color="info" active={!boringView} onClick={this.toggle.bind(this, 'boringView')}>Cool View</Button>
              <Button outline color="info" active={boringView} onClick={this.toggle.bind(this, 'boringView')}>Boring View</Button>
            </ButtonGroup>
          </Col>
          <Col>
            <ButtonGroup>
              <Button outline color="info" active={suppressZeros} onClick={this.toggle.bind(this, 'suppressZeros')}>{suppressZeros ? 'Zeros are oppressed!' : 'Oppress the Zeros!'}</Button>
              <Button outline color="info" active={!suppressZeros} onClick={this.toggle.bind(this, 'suppressZeros')}>{!suppressZeros ? 'Zeros are free!' : 'Free the Zeros!'}</Button>
            </ButtonGroup>
          </Col>
        </Row>
        {boringView && <Row className="mt-1">
          <Col sm={12} className="">
            <Pagination collection={this.propertiesToDisplay()}
                        headers={headers}
                        additionalProps={{setProperty: this.setDetailedProperty.bind(this)}}
                        field="property"
                        component={BoringComponent} />
          </Col>
        </Row>}
        {!boringView && <Row className="mt-1">
          {katsReport.length && this.propertiesToDisplay().map((p, i) => {
            const col = colors(i, katsReport.length);
            return <Col sm={3} key={p.property.id} onClick={this.setDetailedProperty.bind(this, p)}>
              <Card body style={{backgroundColor: col.replace(/, .*\)/, ',0.5)'), borderColor: col}} className="d-flex justify-content-between">
                <span className="d-flex justify-content-between">
                  <Col>
                    <span>
                      {p.property.icon && <img src={p.property.icon} style={{maxHeight: 35}} alt=""/>}
                      <b>{"   "}{p.property.name}</b>
                    </span>
                  </Col>
                  <Col className="d-flex flex-column align-items-end">
                    <span>Open Orders: {p.open_orders}</span>
                    <span>Not Ready Units: {p.not_ready_units.length}</span>
                    <span>Not Inspected Yet: {p.not_inspected_units.length}</span>
                  </Col>
                </span>
              </Card>
            </Col>
          })}
        </Row>}
      </Col>
      {detailed && <DetailedModal property={detailed} toggle={this.setDetailedProperty.bind(this, null)} />}
    </Row>
  }
}

export default connect(({katsReport}) => {
  return {katsReport}
})(KatsReport);