import React from 'react';
import {Modal, ModalHeader, ModalBody, ModalFooter, Button, Row, Col} from 'reactstrap';
import {Phone, SSN} from "../../../../../components/masked";
import Check from '../../../../../components/fancyCheck';
import {ValidatedSelect, ValidatedInput, validate} from '../../../../../components/validationFields';
import {ValidatedDatePicker} from '../../../../../components/validationFields';
import actions from '../../../actions';

class NewTenant extends React.Component {
  state = {};

  save() {
    validate(this).then(() => {
      const {screen, ...person} = this.state;
      const {leaseId, toggle} = this.props;
      if (screen) {
        actions.screenPerson({...person, lease_id: leaseId}).then(toggle);
      } else {
        actions.addTenant(person, leaseId).then(toggle);
      }
    });
  }

  change({target: {name, value}}) {
    this.setState({[name]: value});
  }

  toggleScreen({target: {checked}}) {
    this.setState({screen: checked});
  }

  render() {
    const {toggle} = this.props;
    const {first_name, last_name, email, phone, ssn, income, city, state, street, zip, dob, screen} = this.state;
    const change = this.change.bind(this);
    return <Modal isOpen={true} toggle={toggle}>
      <ModalHeader toggle={toggle}>
        Add Tenant to Lease
      </ModalHeader>
      <ModalBody>
        <Row>
          <Col>
            <div className="labeled-box form-group">
              <ValidatedInput context={this}
                              validation={r => !!r}
                              feedback="Required Field"
                              value={first_name || ''}
                              name="first_name"
                              onChange={change}/>
              <div className="labeled-box-label">First Name</div>
            </div>
            <div className="labeled-box form-group">
              <ValidatedInput mask={Phone}
                              context={this}
                              validation={r => !screen || !!r}
                              feedback="Required Field"
                              value={phone || ''} name="phone" onChange={change}/>
              <div className="labeled-box-label">Phone</div>
            </div>
            <div className="form-group d-flex align-items-center" style={{height: 34}}>
              <Check checked={screen || ''} name="screen" onChange={this.toggleScreen.bind(this)} inline/>
              <div className="ml-2">Screen before adding to lease</div>
            </div>
            {screen && <>
              <div className="labeled-box form-group">
                <ValidatedDatePicker context={this}
                                     validation={r => !!r}
                                     feedback="Required Field"
                                     value={dob || ''} name="dob" onChange={change}/>
                <div className="labeled-box-label">Date of Birth</div>
              </div>
              <div className="labeled-box form-group">
                <ValidatedInput context={this}
                                validation={r => !!r}
                                feedback="Required Field" value={street || ''} name="street" onChange={change}/>
                <div className="labeled-box-label">Street</div>
              </div>
              <div className="labeled-box form-group">
                <ValidatedSelect context={this}
                                 validation={r => !!r}
                                 feedback="Required Field"
                                 value={state || ''} name="state" onChange={change} options={USSTATES}/>
                <div className="labeled-box-label">State</div>
              </div>
            </>}
          </Col>
          <Col>
            <div className="labeled-box form-group">
              <ValidatedInput context={this}
                              validation={r => !!r}
                              feedback="Required Field"
                              value={last_name || ''} name="last_name" onChange={change}/>
              <div className="labeled-box-label">Last Name</div>
            </div>
            <div className="labeled-box form-group">
              <ValidatedInput context={this}
                              validation={r => !screen || !!r}
                              feedback="Required Field"
                              value={email || ''} name="email" type="email" onChange={change}/>
              <div className="labeled-box-label">Email</div>
            </div>
            {screen && <>
              <div className="labeled-box form-group">
                <ValidatedInput context={this}
                                validation={r => !!r}
                                feedback="Required Field"
                                value={income || ''} name="income" type="number" onChange={change}/>
                <div className="labeled-box-label">Monthly Income</div>
              </div>
              <div className="labeled-box form-group">
                <ValidatedInput mask={SSN}
                                context={this}
                                validation={r => !!r}
                                feedback="Required Field"
                                value={ssn || ''} name="ssn" onChange={change}/>
                <div className="labeled-box-label">SSN</div>
              </div>
              <div className="labeled-box form-group">
                <ValidatedInput context={this}
                                validation={r => !!r}
                                feedback="Required Field"
                                value={city || ''} name="city" onChange={change}/>
                <div className="labeled-box-label">City</div>
              </div>
              <div className="labeled-box form-group">
                <ValidatedInput context={this}
                                validation={r => !!r}
                                feedback="Required Field"
                                value={zip || ''} name="zip" onChange={change}/>
                <div className="labeled-box-label">ZIP</div>
              </div>
            </>}
          </Col>
        </Row>
      </ModalBody>
      <ModalFooter>
        <Button color="danger" onClick={toggle}>
          Cancel
        </Button>
        <Button color="success" onClick={this.save.bind(this)}>
          Save
        </Button>
      </ModalFooter>
    </Modal>
  }
}

export default NewTenant;