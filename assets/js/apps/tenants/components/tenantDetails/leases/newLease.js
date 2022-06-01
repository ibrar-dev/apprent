import React from 'react';
import {connect} from 'react-redux';
import {Modal, ModalHeader, ModalBody, ModalFooter, Row, Col, Input, Button} from 'reactstrap';
import moment from 'moment';
import DatePicker from '../../../../../components/datePicker';
import Select from '../../../../../components/select';
import actions from '../../../actions';
import snackbar from '../../../../../components/snackbar';
import confirmation from '../../../../../components/confirmationModal';

class NewLease extends React.Component {
  constructor(props) {
    actions.fetchProperties();
    actions.fetchUnits();
    super(props);
    const {charges, unit: {id: unit_id}, tenant_id} = props.lease;
    const lease = {charges, unit_id, tenant_id};
    lease.charges.forEach(c => {
      delete c.from_date;
      delete c.to_date
    });
    lease.start_date = moment(props.lease.end_date).add(1, 'days').format('YYYY-MM-DD');
    lease.end_date = moment(lease.start_date).add(1, 'year').format('YYYY-MM-DD');
    this.state = {lease};
  }

  change({target: {name, value}}) {
    this.setState({lease: {...this.state.lease, [name]: value}});
  }

  changeCharge(index, e) {
    const charges = [...this.state.lease.charges];
    const c = {...charges[index]};
    c[e.target.name] = e.target.value;
    c.name = this.props.chargeCodes.find(t => parseInt(c.charge_code_id) === t.id).name;
    charges[index] = c;
    this.setState({lease: {...this.state.lease, charges}});
  }

  addCharge() {
    const charges = [...this.state.lease.charges];
    charges.push({charge_code_id: null, name: '', amount: 0});
    this.setState({lease: {...this.state.lease, charges}});
  }

  save() {
    const lease = this.state.lease;
    const oldRent = this.props.lease.charges.find(c => ['Rent', 'HAPRent'].includes(c.charge_code)).amount;
    const newRent = lease.charges.find(c => ['Rent', 'HAPRent'].includes(c.charge_code)).amount;
    const promise = newRent < oldRent ? confirmation('You have entered a rent amount the is lower than the previous rent amount. is this correct?') : {
      then(func) {
        func()
      }
    };
    promise.then(() => {
      actions.createLease(lease).then(() => {
        snackbar({message: 'Lease Created!', args: {type: 'success'}});
        this.props.toggle();
      }).catch(r => {
        snackbar({message: r.response.data.error, args: {type: 'error'}});
      });
    });
  }

  render() {
    const {toggle, properties, units, chargeCodes} = this.props;
    const {lease} = this.state;
    const unit = units.filter(u => u.id === lease.unit_id)[0];
    const property_id = parseInt(lease.property_id) || (unit && unit.property_id);
    const propertyUnits = units.filter(u => u.property_id === property_id);
    properties.sort((a, b) => a.name > b.name ? 1 : -1);
    propertyUnits.sort((a, b) => a.number > b.number ? 1 : -1);
    const change = this.change.bind(this);
    return <Modal isOpen={true} toggle={toggle} size="lg">
      <ModalHeader toggle={toggle}>
        New Lease
      </ModalHeader>
      <ModalBody>
        <Row className="my-2">
          <Col sm={4} className="d-flex align-items-center">Unit</Col>
          <Col>
            <Row>
              <Col>
                <Select name="property_id" onChange={change} value={property_id}
                        options={properties.map(prop => {
                          return {label: prop.name, value: prop.id}
                        })}/>
              </Col>
              <Col>
                <Select name="unit_id" onChange={change} value={lease.unit_id}
                        options={propertyUnits.map(unit => {
                          return {label: unit.number, value: unit.id};
                        })}/>
              </Col>
            </Row>
          </Col>
        </Row>
        <Row className="my-2">
          <Col sm={4} className="d-flex align-items-center">Lease Start</Col>
          <Col>
            <DatePicker name="start_date" value={lease.start_date} onChange={change}/>
          </Col>
        </Row>
        <Row className="my-2">
          <Col sm={4} className="d-flex align-items-center">Lease End</Col>
          <Col>
            <DatePicker name="end_date" value={lease.end_date} onChange={change}/>
          </Col>
        </Row>
        <Row className="my-2">
          <Col sm={4} className="d-flex align-items-center">Deposit Amount</Col>
          <Col>
            <Input type="number" name="deposit_amount" value={lease.deposit_amount} onChange={change}/>
          </Col>
        </Row>
        <h4>Charges <Button onClick={this.addCharge.bind(this)} color="danger" size="sm"><i
          className="fas fa-plus"/></Button></h4>
        {lease.charges.map((charge, index) => {
          return <Row className="my-2" key={charge.id}>
            <Col sm={4}>
              <Select name="charge_code_id" value={charge.charge_code_id}
                      onChange={this.changeCharge.bind(this, index)}
                      options={chargeCodes.map(a => {
                        return {value: a.id, label: `${a.code} - ${a.name}`}
                      })}/>
            </Col>
            <Col>
              <Input type="number" name="amount" value={charge.amount}
                     onChange={this.changeCharge.bind(this, index)}/>
            </Col>
          </Row>
        })}
      </ModalBody>
      <ModalFooter>
        <Button color="success" onClick={this.save.bind(this)}>
          Save
        </Button>
      </ModalFooter>
    </Modal>;
  }
}

export default connect(({properties, units, chargeCodes}) => {
  return {properties, units, chargeCodes};
})(NewLease);