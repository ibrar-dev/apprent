import React, {Component} from 'react';
import {connect} from 'react-redux';
import {Row, Col, Card, CardBody, Table, Input, InputGroup, FormFeedback, FormText, FormGroup} from 'reactstrap';
import DatePicker from '../../../../components/datePicker';
import Select from '../../../../components/select';
import {toCurr} from '../../../../utils';
import actions from '../../actions';
import moment from 'moment';
import FancyCheck from "../../../../components/fancyCheck";
import canEdit from '../../../../components/canEdit';
import isInclusivelyBeforeDay from "react-dates/lib/utils/isInclusivelyBeforeDay";

// const canEdit = (role) => {
//   return (window.roles.includes("Super Admin") || window.roles.includes(role));
// };

class Basics extends Component {
  state = {};

  change({target: {name, value}}) {
    if(name == "rent") return actions.setRent(value);
    if (name === 'start_date') {
      actions.fetchAvailableUnits(this.props.lease.property_id, value.format('YYYY-MM-DD')).then(() => {
        this.props.onChange(name, value);
      });
    } else {
      this.props.onChange(name, value);
    }
  }

  changeUnit({target: {name, value}}){
    const {availableUnits, packages:{default_lease_charges, unit}} = this.props;
    const leaseCharges = availableUnits.find(u => u.number == value).default_lease_charges || default_lease_charges;
    let rent = leaseCharges.reduce((acc, d) => acc + parseFloat(d.price), 0);
    if(unit != value){
      const currentUnit = availableUnits.find(u => u.number == value);
      const [defaultAmt, marketRent] = [currentUnit.default_lease_charges.reduce((acc, d) => acc + parseFloat(d.price), 0), parseFloat(currentUnit.market_rent)];
      rent = marketRent + defaultAmt;
    }
    actions.setRent(rent.toFixed(2));
    actions.setDefaultLeaseCharges(leaseCharges);
    this.setState({...this.state, unitChanged: true});
    this.props.onChange(name, value);
  }

  toggleRenewalPackage(field, value){
    const {defaultLeaseCharges, lease, pack} = this.props;
    if(pack.id == value.id){
      const dlc_amount = defaultLeaseCharges.reduce((acc, val) => !val.unchecked ? acc + parseFloat(val.price) : acc, 0);
      this.props.changeLease({end_date: moment(lease.start_date).add(1, "years").format("YYYY-MM-DD")});
      actions.setRent(dlc_amount.toFixed(2));
      actions.setPackage({});
      this.setState({...this.state, newRenewalPackage: {}})
    }else{
      this.props.changeLease({end_date: moment(lease.start_date).add(value.min, "months").format("YYYY-MM-DD")});
      actions.setRent(value.rent.toFixed(2));
      actions.setPackage(value);
      this.setState({...this.state, newRenewalPackage: {}})
    }
  }

  toggleOpen(){
    this.setState({open: !this.state.open})
  }

  changeMonth({target: {name, value}}){
    const {lease, pack} = this.props;
    const newRenewalPackage = {...pack, months: value};
    this.setState({...this.state, newRenewalPackage});
    const newEndDate = value == "" ? pack.min : parseInt(value);
    if(value >= pack.min && value <= pack.max) this.props.onChange("end_date", moment(lease.start_date).add(newEndDate, "months"))
  }

  changeDefaultCharges(id){
    const {defaultLeaseCharges, rent} = this.props;
    const newDefaultLeaseCharges = [...defaultLeaseCharges];
    newDefaultLeaseCharges[id].unchecked = newDefaultLeaseCharges[id].unchecked ? false : true;
    actions.setDefaultLeaseCharges(newDefaultLeaseCharges);
    const defaultCharge = newDefaultLeaseCharges[id].unchecked ? newDefaultLeaseCharges[id].price : -newDefaultLeaseCharges[id].price
    actions.setRent((rent - defaultCharge).toFixed(2))
  }
  // change property charges
  propertyCharges(){
    const {defaultLeaseCharges} = this.props;
    let totalDLC = 0;
    return <Table>
      <thead>
        <tr>
          <th></th>
          <th>Charge</th>
          <th>Amount</th>
        </tr>
      </thead>
      <tbody>
      {defaultLeaseCharges && defaultLeaseCharges.map((dlc, idx) => {
        if(!dlc.unchecked) totalDLC += parseFloat(dlc.price)
        return <tr key={dlc.id}>
          <td>{!dlc.default_charge ? <FancyCheck inline onChange={this.changeDefaultCharges.bind(this, idx)}
                                                 checked={!dlc.unchecked}/> : null}</td>
          <td>{dlc.account}</td>
          <td>{dlc.price}</td>
        </tr>
      })}
      {totalDLC ? <tr>
        <td></td>
        <td><strong>Total</strong></td>
        <td><strong>{totalDLC}</strong></td>
      </tr> : null}
      </tbody>
    </Table>
  }

  mapPackages(){
    const {packages: {custom_packages, packages, market_rent, start_date, end_date, unit, charges}, defaultLeaseCharges, lease, pack} = this.props;
    const {open, newRenewalPackage} = this.state;
    const newPackages = {};
    packages.forEach(p => newPackages[p.id] = p);
    custom_packages.forEach(p => newPackages[p.renewal_package_id] = {...p, type: true});
    const dlc_amount = defaultLeaseCharges.reduce((acc, val) => !val.unchecked ? acc + parseFloat(val.price) : acc, 0);
    return unit == lease.unit ? <div>
      <a onClick={this.toggleOpen.bind(this)} className="d-flex align-items-center">
        <i className={`fas fa-2x fa-caret-${open ? 'down' : 'right'}`}/>
        <strong className="ml-1">Renewal Options</strong>
      </a>
      <div>
        {open && Object.values(newPackages).map(p => {
          const baseRent = p.base == "Market Rent" ? parseFloat(market_rent) : charges.find(c => c.account == "Rent").amount;
          let rent = p.dollar ? p.amount + baseRent : (p.amount / 100 + 1) * baseRent;
          rent = p.type ? p.amount : rent;
          const state = {rent: rent + dlc_amount, min: p.min, max: p.max, id: p.id, start_date: start_date, end_date: end_date, unit: unit, baseRent: baseRent};
          return <ul className="d-flex" key={p.id}>
            <a onClick={this.toggleRenewalPackage.bind(this, 'renewalPackage', state)}
               className={`input-sm p-1 pl-1 pr-1 rounded ${pack.id == p.id ? 'border border-primary' : ''}`}>
               {p.min} - {p.max} months -- {!p.type && `${p.base}`} {`($${baseRent}) ${p.type ? '-->' : '+'}`} {p.dollar || p.type ? toCurr(p.amount) : `${p.amount}%`}
            </a>
            {pack.id == p.id && <FormGroup className="d-flex flex-column ml-2">
                <Input invalid={newRenewalPackage.months < p.min || newRenewalPackage.months > p.max} type="number" min={p.min} max={p.max} placeholder={p.min}
                value={newRenewalPackage.months ? parseInt(newRenewalPackage.months) : ""} name="renewalPackage" onChange={this.changeMonth.bind(this)} />
                <FormFeedback>Enter A Valid Month</FormFeedback>
             </FormGroup>
            }
          </ul>;
        })}
      </div>
    </div> : null;
  }

  packageValues(){
    const {packages: {custom_packages, packages}} = this.props;
    if(custom_packages && custom_packages.length) return this.mapPackages(true, custom_packages);
    if(packages) return this.mapPackages(false, packages);
  }

  findRange(day){
    const {lease} = this.props;
    if(canEdit(["Super Admin", "Regional"])) return false;
    return isInclusivelyBeforeDay(day, moment(lease.end_date).subtract(15, 'days')) || moment(day).isAfter(moment(lease.end_date).add(15, "days"));
  }

  render() {
    const {lease, availableUnits, rent, packages} = this.props;
    const {unitChanged} = this.state;
    const change = this.change.bind(this);
    return <div>
      <Row className="mr-0">
        <Col md={5}>
          <Card>
            <CardBody>
              <div className="d-flex flex-column form-group">
                <h5>
                  Total Monthly Charges
                </h5>
                <InputGroup>
                  {/*Added In Changing Of Value Until They Start Using The Renewal Package*/}
                  {/*<Input value={rent || ''} name="rent" onChange={change} />*/}
                  <Input value={rent || ''} name="rent" onChange={change} disabled={!canEdit(["Super Admin"]) || (packages.packages || (packages.custom_packages && packages.custom_packages.length > 0))} />
                  {/*<Input value={rent || ''} name="rent" onChange={change} disabled={} />*/}
                </InputGroup>
              </div>
              <div>
                {this.propertyCharges()}
              </div>
              <div>
                {this.packageValues()}
              </div>
            </CardBody>
          </Card>
          <Card>
            <CardBody>
              <div className="d-flex flex-column form-group">
                <h5>
                  Date of Lease
                </h5>
                <DatePicker value={lease.lease_date} name="lease_date" onChange={change}/>
                <small className="form-text text-muted">This is not the lease start date, this is the date the lease was
                  first created.
                </small>
              </div>
            </CardBody>
          </Card>
          <Card>
            <CardBody>
              <div className="d-flex flex-column form-group">
                <h5>
                  Lease Start/End
                </h5>
                <Row>
                  <Col>
                    <div className="labeled-box">
                      {/*<DatePicker value={lease.start_date} name="start_date" disabled={(!unitChanged)} onChange={change}/>*/}
                      <DatePicker value={lease.start_date} name="start_date" disabled={(!canEdit(["Super Admin", "Regional"]) && !unitChanged)} onChange={change}/>
                      <div className="labeled-box-label">Start Date</div>
                    </div>
                  </Col>
                  <Col>
                    <div className="labeled-box">
                      <DatePicker disabled={!canEdit(["Super Admin", "Regional"]) && !unitChanged} value={lease.end_date} isOutsideRange={this.findRange.bind(this)} name="end_date" onChange={change}/>
                      <div className="labeled-box-label">End Date</div>
                    </div>
                  </Col>
                </Row>
              </div>
            </CardBody>
          </Card>
        </Col>
        <Col md={7}>
          <Card>
            <CardBody>
              <div className="d-flex flex-column form-group">
                <h5>Unit</h5>
                <Select options={availableUnits.map(a => {
                  return {label: a.number, value: a.number};
                })} value={lease.unit || ''} name="unit" onChange={this.changeUnit.bind(this)}/>
              </div>
            </CardBody>
          </Card>
          <Card>
            <CardBody>
              <h5>
                People
              </h5>
              <Table className="m-0">
                <thead>
                <tr>
                  <th>Name</th>
                  <th>Status</th>
                  <th/>
                </tr>
                </thead>
                <tbody>
                {lease.signators.map(p => {
                  return <tr key={p.name}>
                    <td className="align-middle">{p.name}</td>
                    <td className="align-middle">Lease Holder</td>
                    <td>
                      Email: {p.email}<br/>
                      Phone: {p.phone}
                    </td>
                  </tr>
                })}
                {lease.occupants.map(p => {
                  return <tr key={p}>
                    <td>{p}</td>
                    <td>Occupant</td>
                    <td/>
                  </tr>
                })}
                </tbody>
              </Table>
            </CardBody>
          </Card>
        </Col>
      </Row>
    </div>
  }
}

export default connect(({availableUnits, packages, defaultLeaseCharges, rent, pack, accounts}) => {
  return {availableUnits, packages, defaultLeaseCharges, rent, pack, accounts};
})(Basics);
