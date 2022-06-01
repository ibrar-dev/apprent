import React from 'react';
import {connect} from 'react-redux';
import Select from 'react-select';
import {Modal, ModalHeader, ModalBody, Row, Col, Input, Button, ButtonGroup} from 'reactstrap';
import actions from '../actions';
import axios from 'axios';
import Mail from '../images/envelope.svg';
import NotTen from '../images/cancel.svg';

const statusOptions = [{value: 'Pending', label: 'Pending'}, {value: 'Undeliverable', label: 'Undeliverable'}];
const mailOp = ['Amazon', 'FedEx', 'UPS', 'USPS', 'LaserShip', 'DHL', 'Florist', 'Dry Cleaner', 'Other'];
const typeOp = ['Box', 'Box(Large)', 'Box(Small)', 'Tube', 'Tube(Large)', 'Tube(Small)', 'Envelope', 'Envelope(Soft Pack)', 'Envelope(Large)', 'Container', 'Pallet', 'Crate', 'Perishable', 'Flowers', 'Dry Cleaning', 'Books', 'Other'];
const condOp = ['Normal', 'Crushed', 'Damaged', 'Empty', 'Leaking', 'Open', 'Ripped', 'Torn', 'Wet'];

const requiredStyles = {
  control: styles => ({...styles, borderColor: 'red'})
};

const requiredStyles2 = {
  control: styles => ({...styles, borderColor: 'green'})
};

class NewPackage extends React.Component {

  constructor(props) {
    super(props);
    const {tenants} = props
    const tenantsOptions = tenants.map(tenant => {
      return {
        value: {
          unit: tenant.leases[0].number,
          unit_id: tenant.leases[0].id,
          property: tenant.leases[0].property,
          leases: tenant.leases,
          email: tenant.email,
          id: tenant.id
        }, label: `${tenant.name}`
      };
    });

    const unitOptions = tenants.map(tenant => {
      return {value: tenant.leases[0].id, label: `${tenant.leases[0].property} ${tenant.leases[0].number}`};
    });

    const carrierOptions = mailOp.map(op => {
      return {value: op, label: op};
    });
    const typeOptions = typeOp.map(op => {
      return {value: op, label: op};
    });
    const conditionOptions = condOp.map(op => {
      return {value: op, label: op};
    });

    this.state = {
      unit_id: '',
      status: '',
      carrier: '',
      tenants: this.props.tenants,
      tracking_number: '',
      notes: '',
      type: '',
      condition: '',
      filterVal: ' ',
      bySearch: false,
      tenValue: '',
      packageType: 1,
      unit: '',
      unitOptions: unitOptions,
      tenantsOptions: tenantsOptions,
      carrierOptions: carrierOptions,
      typeOptions: typeOptions,
      conditionOptions: conditionOptions
    };
  }

  change(e) {
    this.setState({...this.state, [e.target.name]: e.target.value});
  }

  changeUnit(e) {
    var status = statusOptions[0];
    var unitTenant = null;
    const name = this.state.tenants.filter(x => x.leases[0].id === e.value)[0].name;
    const tenant_id = this.state.tenants.filter(x => x.leases[0].id === e.value)[0].id;
    if (this.state.tenants.filter(x => x.leases[0].id === e.value).length === 1) {
      status = statusOptions[0];
      unitTenant = this.state.tenants.filter(x => x.leases[0].id === e.value).map(op => {
        return {value: {email: op.email, leases: op.leases, tenant_id: tenant_id}, label: op.name};
      })[0];
    }
    this.setState({
      ...this.state,
      unit: e || '',
      unit_id: e.value,
      bySearch: false,
      name: name,
      tenant_id: tenant_id,
      unitTenant: unitTenant,
      status: status,
      filterVal: ''
    });
  }

  changeCarrier(e) {
    this.setState({...this.state, carrier: e || ''});
  }

  changeUnitTenant(e) {
    let status = statusOptions[0];
    if ((e.value.leases.filter(x => x.current_tenant).length === 0)) {
      status = statusOptions[1]
    }
    this.setState({
      ...this.state,
      unitTenant: e || '',
      name: e.label,
      tenant_id: e.value.tenant_id,
      status: status,
      filterVal: ''
    });
  }

  changeStatus(status) {
    this.setState({...this.state, status: status || ''});
  }

  changeCondition(condition) {
    this.setState({...this.state, condition: condition});
  }

  changeType(e) {
    this.setState({...this.state, type: e});
  }

  submit() {
    const unit_id = this.state.unit_id;
    const name = this.state.name;
    const carrier = this.state.carrier.value;
    const status = this.state.status.value;
    const type = this.state.type.value;
    const condition = this.state.condition.value;
    const notes = this.state.notes;
    const tracking_number = this.state.tracking_number;
    const tenant_id = this.state.tenant_id;
    const pack = {
      unit_id: unit_id,
      carrier: carrier,
      status: status,
      type: type,
      condition: condition,
      tracking_number: tracking_number,
      name: name,
      notes: notes,
      tenant_id: tenant_id
    };
    actions.savePackage(pack)
      .then((function (toggle, response) {
        if (response.data.error === "noEmail") {
          alert("Error (No Email for tenant): Package has been logged but tenant has not been notified. Handle accordingly.");
        } else if (response.data.error === "endLease") {
          alert("Error (Expired Lease): Package has been logged but tenant has not been notified. Handle accordingly.");
        } else {
          alert("Success: Tenant has been notified about package");
        }
        toggle();
      }).bind(this, this.props.toggle))
      .catch(() => {
        alert("ERROR logging package ");
      });

  }

  filter(e) {
    var unitTenant = {value: {email: e.value.email, leases: e.value.leases}, label: e.label};
    var status = unitTenant.value.leases[unitTenant.value.leases.length - 1].current_tenant ? statusOptions[0] : statusOptions[1];
    e.value != null ? this.setState({
        ...this.state,
        bySearch: true,
        unit_id: e.value.unit_id,
        unitTenant: unitTenant,
        status: status,
        name: e.label,
        tenant_id: e.value.id,
        unitVal: {value: e.value.unit_id, label: `${e.value.property} ${e.value.unit}`},
        filterVal: e
      })
      : this.setState({
        ...this.state,
        bySearch: true,
        unit_id: '',
        unitTenant: '',
        unitVal: {value: '', label: '', filterVal: ''},
        filterVal: ''
      })

  }

  unitTenantOptions() {
    return this.state.tenants.filter(x => (x.leases.some(x => x.id === this.state.unit_id))).map(op => {
      return {value: {email: op.email, leases: op.leases, tenant_id: op.id}, label: op.name};
    })
  }

  updateTenants(inputValue, callback) {
    axios.get(`/api/tenants?name=${inputValue}`).then(r => {
      callback(
        r.data.tenants.map(tenant => {
          return {
            value: {
              unit: tenant.leases[0].unit.number,
              unit_id: tenant.leases[0].unit_id,
              property: tenant.leases[0].property,
              leases: tenant.leases,
              email: tenant.email
            }, label: `${tenant.name}`
          };
        }))
    })
  }

  updateUnits(inputValue, callback) {
    axios.get(`/api/tenants?name=${inputValue}`).then(r => {
      callback(
        r.data.units.map(unit => {
          return {value: unit.id, label: `${unit.property} ${unit.number}`};
        }))
    })
  }

  clearForm() {
    this.setState({
      ...this.state,
      filterVal: '',
      unitVal: undefined,
      unit: '',
      carrier: '',
      status: '',
      type: '',
      condition: '',
      tracking_number: '',
      notes: '',
      unit_id: ''
    })
  }

  packageType(type) {
    this.setState({...this.state, packageType: type});
  }

  render() {
    const {toggle, tenants} = this.props;
    const {unit_id, status, carrier, condition, type, tracking_number, filterVal, bySearch, unitVal, notes, unit, unitTenant, packageType, tenantsOptions, unitOptions, carrierOptions, typeOptions, conditionOptions} = this.state;
    const change = this.change.bind(this);

    return <Modal isOpen={true} toggle={toggle}>
      <ModalHeader toggle={toggle}>
        <Row>
          <Col>
            New Package
          </Col>
          <Col>
            {/*<ButtonGroup>*/}
              {/*<Button outline color="secondary" onClick={this.packageType.bind(this, 1)} size="sm"*/}
                      {/*active={packageType === 1}>Tenant</Button>*/}
              {/*<Button outline color="secondary" onClick={this.packageType.bind(this, 2)} size="sm"*/}
                      {/*active={packageType === 2}>Property</Button>*/}
            {/*</ButtonGroup>*/}
          </Col>
        </Row>
      </ModalHeader>

      <ModalBody>
        {packageType === 1 && <React.Fragment>
          <Row className="mb-2">
            <Col sm={3}>
              <b/>
            </Col>
            <Col sm={9} style={{paddingBottom: "20px"}}>
              <Select value={filterVal}
                      placeholder={"search by name"}
                      options={tenantsOptions}
                      onChange={this.filter.bind(this)}/>
            </Col>
          </Row>
          <Row className="mb-2">
            <Col sm={3}>
              <b>Unit</b>
            </Col>
            <Col sm={9}>
              <Select value={(bySearch && filterVal) ? unitVal : unit}
                      onChange={this.changeUnit.bind(this)}
                      options={unitOptions}
                      styles={unitVal === undefined && unit === '' ? requiredStyles : requiredStyles2}
              />
              {!bySearch && tenants.filter(x => (x.leases.some(x => x.id === unit_id))).length > 1 &&
              <div>
                <small className="text-muted"> Select name on package</small>
                <Select value={unitTenant}
                        multi={false}
                        options={this.unitTenantOptions()}
                        onChange={this.changeUnitTenant.bind(this)}
                        styles={unitTenant === undefined ? requiredStyles : requiredStyles2}/>
              </div>
              }
            </Col>
          </Row>
          <Row className="mb-2" style={{borderColor: "#dc3545"}}>
            <Col sm={3}>
              <b>Carrier</b>
            </Col>
            <Col sm={9}>
              <Select value={carrier}
                      multi={false}
                      options={carrierOptions}
                      onChange={this.changeCarrier.bind(this)}
                      styles={carrier === "" ? requiredStyles : requiredStyles2}/>
            </Col>
          </Row>
          <Row className="mb-2">
            <Col sm={3}>
              <b>Status</b>
            </Col>
            <Col sm={9}>
              <Select value={status}
                      multi={false}
                      options={statusOptions}
                      onChange={this.changeStatus.bind(this)}
                      styles={status === "" ? requiredStyles : requiredStyles2}/>
            </Col>
          </Row>
          <Row className="mb-2">
            <Col sm={3}>
              <b>Type</b>
            </Col>
            <Col sm={9}>
              <Select value={type}
                      multi={false}
                      options={typeOptions}
                      onChange={this.changeType.bind(this)}/>
            </Col>
          </Row>
          <Row className="mb-2">
            <Col sm={3}>
              <b>Condition</b>
            </Col>
            <Col sm={9}>
              <Select value={condition}
                      multi={false}
                      options={conditionOptions}
                      onChange={this.changeCondition.bind(this)}/>
            </Col>
          </Row>
          <Row className="mb-2">
            <Col sm={3}>
              <b>Tracking Number</b>
            </Col>
            <Col sm={9}>
              <Input name="tracking_number" value={tracking_number} onChange={change}/>
            </Col>
          </Row>
          <Row className="mb-2">
            <Col sm={3}>
              <b>Notes</b>
            </Col>
            <Col sm={9}>
              <Input type="textarea" name="notes" value={notes} onChange={change}/>
            </Col>
          </Row>
          <Row style={{marginTop: "15px"}}>
            <Col>
              <Button
                disabled={(unit_id !== undefined && unit_id.length === 0) || (carrier !== undefined && carrier.length === 0) || (status !== undefined && status.length === 0) || (tenants.filter(x => (x.leases.some(x => x.id === unit_id))).length > 1 && unitTenant === undefined)}
                onClick={this.submit.bind(this)} color="success">
                Submit
              </Button>
              <Button style={{marginLeft: "10px"}} onClick={this.clearForm.bind(this)} color="secondary">
                Clear
              </Button>

            </Col>
            <Col>
              {unit_id && unitTenant && ((unitTenant.value.leases.filter(x => x.is_current || x.current_tenant).length === 0) &&
                <div>
                  <img src={NotTen} height="20" color="white"/>
                  <small style={{color: 'red', lineHeight: "1"}}> Note: This tenants lease is expired, mark as
                    undeliverable and return to sender.
                  </small>
                </div>)
              ||
              unit_id && unitTenant && (!(unitTenant.value.email) && <div>
                <img src={Mail} height="20" color="white"/>
                <small style={{color: 'red', lineHeight: "1"}}> Note: This tenant doesnt have an email and wont be
                  notified, handle accordingly.
                </small>
              </div>)
              }
            </Col>
          </Row>
        </React.Fragment>}
      </ModalBody>
    </Modal>;
  }
}

export default connect(({tenants}) => {
  return {tenants};
})(NewPackage);