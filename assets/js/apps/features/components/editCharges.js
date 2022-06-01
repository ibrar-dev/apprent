import React from 'react';
import {connect} from 'react-redux';
import {Modal, ModalHeader, ModalBody, Button, Input, Row, Col, FormGroup, Label, ModalFooter, Collapse} from 'reactstrap';
import Select from '../../../components/select';
import {validate, ValidatedInput, ValidatedSelect} from '../../../components/validationFields';
import actions from '../actions';
import confirmation from '../../../components/confirmationModal';

class EditCharges extends React.Component {
  state = {
    charges: this.props.floorPlan.charges,
    newCharges: []
  };


  increment() {
    const {newCharges} = this.state;
    newCharges.push({price: "", charge_code_id: null});
    this.setState({...this.state, newCharges})
  }

  handleChange(charge, {target: {name, value}}) {
    const {charges, newCharges} = this.state;
    if(Number.isInteger(charge)){
      let newCharge = newCharges[charge];
      newCharge[name] = value;
      newCharges.splice(charge, 1, newCharge);
      this.setState({...this.state, newCharges: newCharges});
    }else{
      let newCharge = charges.filter(c => c.id === charge.id)[0];
      newCharge[name] = value;
      charges.splice(charges.indexOf(charge), 1, newCharge);
      this.setState({...this.state, charges});
    }
  }

  handleDefaultChange(charge, value) {
    const {charges} = this.state;
    if (charge) {
      let newCharge = charges.filter(c => c.id === charge.id)[0];
      newCharge.default_charge = value;
      charges.splice(charges.indexOf(charge), 1, newCharge);
      this.setState({...this.state, charges});
    }
  }

  saveAll(){
    const {newCharges} = this.state;
    if(newCharges.length){
      validate(this).then(() => {
        const {floorPlan} = this.props;
        const postCharges = newCharges.map((nc, i) => {
          const {price, charge_code_id} = nc;
          const default_charge = nc[`${i}-new_default_charge`] == "true" ? true : false;
          return {price: price, charge_code_id: charge_code_id, default_charge: default_charge, floor_plan_id: floorPlan.id}
        });
        actions.saveDefaultCharges(postCharges);
        actions.updateDefaultCharges(this.state.charges);
      }).catch(() => {});
    }else{
      actions.updateDefaultCharges(this.state.charges);
    }
  }

  clearNew() {
    this.setState({...this.state, new_price: null, new_default_charge: null}, () => this.render())
  }

  deleteCharge(charge) {
    actions.deleteCharge(charge.id)
  }

  deleteNewCharge(idx){
    const {newCharges} = this.state;
    newCharges.splice(idx, 1);
    this.setState({...this.state, newCharges})
  }

  toggleClone() {
    this.setState({...this.state, clone: !this.state.clone})
  }

  cloneCharges(floor_plan) {
    confirmation(`Please confirm you would like to set these charges to this floor plan: ${floor_plan.charges.map(c => {
      return `$${c.price} | `
    })}`).then(() => {
      actions.cloneCharges(floor_plan.id, this.props.floorPlan.id)
    })
  }

  render() {
    const {chargeCodes, toggle, floorPlans} = this.props;
    const {charges, newCharges, clone} = this.state;
    if (charges.length < 1) this.increment.bind(this);
    return <Modal isOpen={true} toggle={toggle} size="lg">
      <ModalHeader toggle={toggle} className="d-flex">
          <p>Set the default leases for this floor plan</p>
          <small>These are the charges that will always be on the lease when a lease gets created</small>
      </ModalHeader>
      <ModalBody>
        <div className="d-flex justify-content-between mb-1">
          <div><h4><strong>Charges</strong></h4></div>
          <Button onClick={this.increment.bind(this)} className="btn btn-success">
            <i className="fas fa-plus"/>
          </Button>
        </div>
        {charges.map(c => {
          return <Row key={c.id}>
            <Col>
              <Input value={c.price} name="price" type="number" onChange={this.handleChange.bind(this, c)} />
            </Col>
            <Col>
              <Select value={c.charge_code_id}
                      name="charge_code_id"
                      onChange={this.handleChange.bind(this, c)}
                      options={chargeCodes.map(a => {
                        return {value: a.id, label: `${a.code} - ${a.name}`}
                      })} />
            </Col>
            <Col>
              <FormGroup tag="fieldset">
                <FormGroup check>
                  <Label check>
                    <Input type="radio" checked={c.default_charge} name={`${c.id}-default_charge`} value={true} onChange={this.handleDefaultChange.bind(this, c, true)} />{' '}
                    Default Lease Charge
                  </Label>
                </FormGroup>
                <FormGroup check>
                  <Label check>
                    <Input type="radio" checked={!c.default_charge} name={`${c.id}-default_charge`} value={false} onChange={this.handleDefaultChange.bind(this , c, false)} />{' '}
                    Non Default Lease Charge
                  </Label>
                </FormGroup>
              </FormGroup>
            </Col>
            <Col xs={1}>
              <i onClick={this.deleteCharge.bind(this, c)} style={{cursor: 'pointer'}} className="fas fa-trash" />
            </Col>
          </Row>
        })}
        {newCharges && newCharges.map((nc, i) => {
          const {price, charge_code_id} = nc;
          const default_charge = nc[`${i}-new_default_charge`] == "true" ? true : false;
          return <Row key={i}>
            <Col>
              <ValidatedInput context={this} validation={v => !!v} feedback="Insert A Value" value={price} name="price" type="number" onChange={this.handleChange.bind(this, i)} />
            </Col>
            <Col>
              <ValidatedSelect context={this}
                      value={charge_code_id}
                      name="charge_code_id"
                      validation={v => !!v}
                      feedback="Select an Account"
                      onChange={this.handleChange.bind(this, i)}
                      options={chargeCodes.map(a => {
                        return {value: a.id, label: `${a.code} - ${a.name}`}
                      })} />
            </Col>
            <Col>
              <FormGroup tag="fieldset">
                <FormGroup check>
                  <Label check>
                    <Input type="radio" checked={default_charge} name={`${i}-new_default_charge`} value={true} onChange={this.handleChange.bind(this, i)} />{' '}
                    Default Lease Charge
                  </Label>
                </FormGroup>
                <FormGroup check>
                  <Label check>
                    <Input type="radio" checked={!default_charge} name={`${i}-new_default_charge`} value={false} onChange={this.handleChange.bind(this, i)} />{' '}
                    Non Default Lease Charge
                  </Label>
                </FormGroup>
              </FormGroup>
            </Col>
            <Col xs={1}>
              <i onClick={this.deleteNewCharge.bind(this, i)} style={{cursor: 'pointer'}} className="fas fa-trash" />
            </Col>
          </Row>
        })}
      </ModalBody>
      <ModalFooter className="d-flex justify-content-start">
        <Row className="d-flex flex-column w-100">
          <Col className="d-flex justify-content-between">
            <Button className="btn btn-success" onClick={this.saveAll.bind(this)}>Save Charges</Button>
            <Button onClick={this.toggleClone.bind(this)}>Clone Charges</Button>
          </Col>
          <Col>
            <Collapse isOpen={clone}>
              {floorPlans.filter(f => (f.property_id === this.props.floorPlan.id) && (f.charges && f.charges.length > 0)).map(f => {
                return <Row key={f.id} className="d-flex justify-content-between mt-1">
                  <Col>
                    <Button onClick={this.cloneCharges.bind(this, f)} block outline color="success">
                      {f.name}
                    </Button>
                  </Col>
                </Row>
              })}
            </Collapse>
          </Col>
        </Row>
      </ModalFooter>
    </Modal>
  }
}

export default connect(({chargeCodes, floorPlans}) => {
  return {chargeCodes, floorPlans}
})(EditCharges);