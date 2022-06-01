import React from 'react';
import {connect} from 'react-redux';
import {Modal, ModalHeader, ModalBody, Table, Label, Input, Row, Col, Button, Alert, Collapse, ButtonGroup} from 'reactstrap';
import {InputGroup, ModalFooter} from 'reactstrap';
import DatePicker from '../../../components/datePicker';
import isInclusivelyBeforeDay from "react-dates/lib/utils/isInclusivelyBeforeDay";
import moment from "moment";
import confirmation from '../../../components/confirmationModal';
import Select from '../../../components/select';
import Charge from './charge';
import actions from '../actions';
import {capitalize} from '../../../utils';

const canEdit = (role) => {
  return (window.roles.includes("Super Admin") || window.roles.includes(role));
};

class ApprovalModal extends React.Component {
  constructor(props) {
    super(props);
    const {persons, params} = props;
    const personParams = persons.map(person => {
      const name = person.full_name.split(' ');
      return {
        first_name: name.shift(),
        last_name: name.join(' '),
        email: person.email,
        phone: (person.home_phone || person.cell_phone || person.work_phone),
        status: person.status
      };
    });
    if (params.start_date) {
      const start = moment(params.start_date);
      const end = moment(params.end_date);
      if(params.unit_id) actions.fetchUnitInfo(params.unit_id).then((r) => this.setState({rent: r.data.default_price}));
      // const rent = params.charges.find(c => c.name === 'Rent');
      this.state = {
        ...params,
        persons: personParams,
        rent: null,
        default_rent: false,
        leaseLength: Math.round(end.diff(start, 'months', true)),
        charges: params.charges.filter(p => p.name !== "Rent" && !p.default_charge),
        additionalCharges: [],
        showCharges: true,
        start_date: moment(params.start_date),
        deposit_amount: params.deposit_amount
      };
      actions.fetchAvailableUnits(props.propertyId, start.format('YYYY-MM-DD'));
    } else if (persons.length > 0) {
      // const rent = props.unit.default_price;
      this.state = {
        persons: personParams,
        rent: null,
        default_rent: false,
        deposit_type: 'deposit',
        leaseLength: '',
        charges: [],
        additionalCharges: [],
        deposit_amount: params.deposit_amount
      };
    }
  }

  componentWillUnmount(){
    actions.setUnitInfo({})
  }

  static getDerivedStateFromProps(props, state) {
    let rent = props.params && props.params.charges && props.params.charges.find(c => c.name == "Rent").amount;
    if(props.unitInfo && props.unitInfo.default_price) rent = props.unitInfo.default_price;
    let default_rent = rent && rent != "0" ? true : false;
    if(canEdit("Super Admin")) default_rent = false;
    return {default_rent: default_rent};
  }

  dismissError() {
    this.setState({error: null});
  }

  change(e) {
    if (!e) return;
    const {target: {name, value}} = e;
    if ((name === 'leaseLength' && isNaN(value))) return;
    this.setState({[name]: value});
  }

  changeUnit({target: {name, value}}) {
    this.setState({[name]: value, charges: [], rent: null});
    actions.fetchUnitInfo(value).then((r) => this.setState({rent: r.data.default_price}))
  }

  changePerson(index, {target: {name, value}}) {
    const {persons} = this.state;
    persons[index] = {...persons[index], [name]: value};
    this.setState({persons});
  }

  updateCalendar(date) {
    actions.fetchAvailableUnits(this.props.propertyId, date.format('YYYY-MM-DD')).then(() => {
      this.setState({start_date: date});
    });
  }

  valid() {
    const {first_name, last_name, start_date, end_date, rent, unit_id, email, phone, charges} = this.state;
    if (charges.some(c => !(c.charge_code_id && c.amount))) return false;
    return !!(first_name && last_name && start_date && end_date && rent && unit_id && email && phone);
  }

  submit() {
    // confirmation("Finishing the approval will send an email to the applicant, inviting them to pay the Admin Fee and setting their status to Pre-Approved. \nWhen the applicant pays the fee they will automatically be moved into the Approved status. \nPlease confirm that you would like to Pre-Approve the resident").then(() => {
    confirmation("Ready to approve?").then(() => {
      const params = {...this.state};
      params.end_date = this.calculateEndDate();
      params.rent = parseInt(params.rent);
      const newCharges = [];
      this.props.unitInfo.default_charges.forEach(dc => {
        if(!dc.unchecked) newCharges.push({amount: dc.price, charge_code: dc.charge_code, charge_code_id: dc.charge_code_id, default_charge: dc.default_charge});
      });
      params.charges.forEach(c => {
        newCharges.push({amount: parseInt(c.amount), account: this.props.chargeCodes.find(a => a.id === c.charge_code_id).name, charge_code_id: c.charge_code_id, default_charge: false})
      });
      params.additionalCharges.forEach(c => {
        newCharges.push({amount: parseInt(c.amount), account: this.props.chargeCodes.find(a => a.id === c.charge_code_id).name, charge_code_id: c.charge_code_id, from_date: params.start_date, to_date: moment(params.start_date).add(1, "months")})
      })
      params.charges = newCharges;
      actions.approveApplication(this.props.applicationId, params).then(this.props.toggle);
    })
  }

  addCharge(type) {
    const charges = this.state[type];
    const maxId = charges.reduce((max, c) => c._id > max ? c._id : max, 0);
    charges.unshift({_id: maxId + 1});
    this.setState({[type]: charges});
  }

  deleteCharge(id) {
    const {charges: old} = this.state;
    const charges = old.filter(c => c._id !== id);
    this.setState({charges});
  }

  changeCharge(id, params) {
    const {charges: old} = this.state;
    const charges = old.map(c => {
      return c._id === id ? {...c, ...params} : c
    });
    this.setState({charges});
  }

  changeAdditionalCharge(id, params) {
    const {additionalCharges: old} = this.state;
    const charges = old.map(c => {
      return c._id === id ? {...c, ...params} : c
    });
    this.setState({additionalCharges: charges});
  }

  deleteAdditionalCharge(id) {
    const {additionalCharges: old} = this.state;
    const additionalCharges = old.filter(c => c._id !== id);
    this.setState({additionalCharges});
  }

  changeSecurityDeposit({target: {value}}){
    this.setState({deposit_amount: value})
  }

  setDepositType(type){
    this.setState({deposit_type: type})
  }

  calculateEndDate() {
    const {leaseLength, start_date} = this.state;
    return moment(start_date).add(leaseLength, 'M').subtract(1, 'd');
  }

  progress() {
    const {start_date, unit_id, leaseLength, rent} = this.state;
    const validLeaseLength = leaseLength >= 3 && leaseLength <= 14;
    if (start_date && validLeaseLength && unit_id && rent) return 100;
    if (start_date && validLeaseLength && unit_id) return 75;
    if (start_date && validLeaseLength) return 50;
    if (start_date) return 25;
    return 0;
  }

  toggleCharges() {
    this.setState({showCharges: !this.state.showCharges});
  }

  toggleDLC(idx){
    const newUnitInfo = {...this.props.unitInfo};
    newUnitInfo.default_charges[idx].unchecked = !newUnitInfo.default_charges[idx].unchecked;
    actions.setUnitInfo(newUnitInfo);
  }

  render() {
    const {toggle, availableUnits, unitInfo, chargeCodes} = this.props;
    const {start_date, rent, unit_id, leaseLength, error, charges, additionalCharges, showCharges, persons, default_rent, deposit_amount, deposit_type} = this.state;
    const validLeaseLength = leaseLength >= 3 && leaseLength <= 14;
    const change = this.change.bind(this);
    const chargesDict = {};
    charges.forEach(c => chargesDict[c.charge_code_id] = c);
    return <Modal isOpen={true} toggle={toggle} size="lg">
      <ModalHeader toggle={toggle}>
        Approve Application
      </ModalHeader>
      <ModalBody>
        <Alert isOpen={!!error} color="danger" toggle={this.dismissError.bind(this)}>
          {capitalize(error)}
        </Alert>
        {persons.map((person, index) => <React.Fragment key={index}>
          <h4>{person.status}</h4>
          <Row className="mb-3">
            <Col>
              <div className="labeled-box">
                <Input value={person.first_name || ''} name="first_name"
                       onChange={this.changePerson.bind(this, index)}/>
                <div className="labeled-box-label">First Name</div>
              </div>
            </Col>
            <Col>
              <div className="labeled-box">
                <Input value={person.last_name || ''} name="last_name" onChange={this.changePerson.bind(this, index)}/>
                <div className="labeled-box-label">Last Name</div>
              </div>
            </Col>
          </Row>
          <Row  className="mb-4">
            <Col>
              <div className="labeled-box">
                <Input value={person.email || ''} type="email" name="email"
                       onChange={this.changePerson.bind(this, index)}/>
                <div className="labeled-box-label">Email</div>
              </div>
            </Col>
            <Col>
              <div className="labeled-box">
                <Input value={person.phone || ''} name="phone" onChange={this.changePerson.bind(this, index)}/>
                <div className="labeled-box-label">Phone</div>
              </div>
            </Col>
          </Row>
        </React.Fragment>)}
        <Row>
          <Col>
            <div className="form-group">
              <Label className="d-block">
                Security Deposit
              </Label>
              <ButtonGroup className='mb-1'>
                <Button size='sm' onClick={this.setDepositType.bind(this, "deposit")} active={deposit_type === "deposit"}
                        color="info">Deposit</Button>
                <Button size='sm' onClick={this.setDepositType.bind(this, "bond")} active={deposit_type === "bond"}
                  color="info">Bond</Button>
                <Button size='sm' onClick={this.setDepositType.bind(this, "epremium")} active={deposit_type === "epremium"}
                  color="info">ePremium</Button>
              </ButtonGroup>
              <Input value={deposit_amount || ''} onChange={this.changeSecurityDeposit.bind(this)} />
            </div>
          </Col>
        </Row>
        <Row>
          <Col>
            <div className="form-group">
              <Label className="d-block">
                Lease Start Date{" "}
              </Label>
              <DatePicker value={start_date}
                          isOutsideRange={canEdit("Super Admin") ? () => {} : day => isInclusivelyBeforeDay(day, moment().subtract(1, 'days'))}
                          onChange={this.updateCalendar.bind(this)}/>
              <small className="form-text text-muted">Available Units Will Automatically Show After Start Date Has Been
                Selected
              </small>
            </div>
          </Col>
          <Col>
            <Collapse isOpen={!!start_date}>
              <div className="form-group">
                <Label className="d-block">
                  Lease Length
                </Label>
                <Row>
                  <Col sm={12}>
                    <InputGroup>
                      <Input className={`is-${validLeaseLength ? 'valid' : 'invalid'}`}
                             placeholder="Number" type="integer" name="leaseLength"
                             value={leaseLength || ''} onChange={change}/>
                      <div className="input-group-append">
                        <span
                          className={`input-group-text bg-white form-control is-${validLeaseLength ? 'valid' : 'invalid'}`}>
                          Months
                        </span>
                      </div>
                    </InputGroup>
                  </Col>
                </Row>
                <small className="form-text text-muted">Must Be Between 3 and 14</small>
              </div>
            </Collapse>
          </Col>
          <Col>
            <Collapse isOpen={validLeaseLength}>
              <div className="form-group">
                <Label>
                  Select a Unit
                </Label>
                <Select value={unit_id || ''}
                        onChange={this.changeUnit.bind(this)}
                        name="unit_id"
                        options={availableUnits.map(u => {
                          return {value: u.id, label: u.number};
                        })}/>
                <small className="form-text text-muted">Only units that are available on the selected date will show
                  up.
                </small>
              </div>
            </Collapse>
          </Col>
        </Row>
        <Collapse isOpen={this.progress() >= 75}>
          <Row>
            <Col>
              <p>Lastly please set a rent charge amount. This will be a {leaseLength} month lease.</p>
              <p>Starting on {moment(start_date).format("dddd MMMM DD, YYYY")} and ending
                on {this.calculateEndDate().format("dddd MMMM DD, YYYY")}</p>
              <div className='form-group'>
                <Label>Base rent will be $</Label>
                <Input value={rent || ''} type="number" name="rent" disabled={default_rent} onChange={change}/>
                <small>per month.</small>
              </div>
              {this.progress() >= 100 && <div>
                <strong>Total Charge: {unitInfo.default_charges.reduce((acc, c) => !c.unchecked ? acc + parseFloat(c.price) : acc, 0) + parseFloat(rent) + additionalCharges.reduce((acc, c) => acc + parseFloat(c.amount), 0)}</strong>
              </div>}
            </Col>
          </Row>
        </Collapse>
          <Table bordered className="mt-4">
            <thead>
            <tr>
              <th className="min-width">
                <a onClick={this.addCharge.bind(this, "charges")}>
                  <i className="fas fa-plus-circle"/>
                </a>
              </th>
              <th style={{width: 300}}>Charge</th>
              <th>Amount</th>
            </tr>
            </thead>
            <tbody>
            {unitInfo && unitInfo.default_charges && unitInfo.default_charges.map((c, i) => {
              const a = chargeCodes.filter(a => a.id === c.charge_code_id)[0];
              return <tr key={c.id} className="table-active">
                <td>{!c.default_charge ? <input type="checkbox" onClick={this.toggleDLC.bind(this, i)} checked={!c.unchecked}/> : null}</td>
                <td>{a.name}</td>
                <td>${c.price}</td>
              </tr>
            })}
            {charges && charges.map(c => <Charge key={c._id || c.charge_code_id}
                                      defaultCharge={c.default_charge}
                                      onDelete={this.deleteCharge.bind(this)}
                                      onChange={this.changeCharge.bind(this)}
                                      charge={c}/>)}
            </tbody>
          </Table>
        {showCharges && <Table bordered className="mt-4">
          <thead>
          <tr>
            <th className="min-width">
              <a onClick={this.addCharge.bind(this, "additionalCharges")}>
                <i className="fas fa-plus-circle"/>
              </a>
            </th>
            <th style={{width: 300}}>Additional Charge</th>
            <th>Amount</th>
          </tr>
          </thead>
          <tbody>
          {additionalCharges && additionalCharges.map(c => <Charge key={c._id || c.charge_code_id}
                                                       defaultCharge={c.default_charge}
                                                       onDelete={this.deleteAdditionalCharge.bind(this)}
                                                       onChange={this.changeAdditionalCharge.bind(this)}
                                                       charge={c}/>)}
          </tbody>
        </Table>}
        {this.progress() >= 100 &&
        <Row>
          <Col sm={6} className="mt-1">
            <Button color="info" className="btn-block" onClick={this.toggleCharges.bind(this)}>
              {showCharges ? 'Hide' : 'Show'} Additional Charges
            </Button>
          </Col>
          <Col sm={6} className="mt-1">
            <Button color="success" className="btn-block" onClick={this.submit.bind(this)}>
              Finish Approval
            </Button>
          </Col>
        </Row>}
      </ModalBody>
      <ModalFooter>
        <div className="progress w-100">
          <div className="progress-bar bg-success"
               role="progressbar"
               style={{height: 75, width: `${this.progress()}%`}}
               aria-valuenow={this.progress()}
               aria-valuemin="0" aria-valuemax="100">
          </div>
        </div>
      </ModalFooter>
    </Modal>
  }
}

export default connect(({chargeCodes, availableUnits, unitInfo}) => {
  return {chargeCodes, availableUnits, unitInfo};
})(ApprovalModal);
