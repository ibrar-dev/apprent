import React from 'react';
import {Modal, ModalHeader, ModalBody, ModalFooter, Row, Col, Button} from 'reactstrap';
import {ValidatedInput, ValidatedSelect, validate} from '../../../../../components/validationFields';
import actions from '../../../actions';

class CreatePayscape extends React.Component {
  state = {
    account_ownership_type: 'Business',
    account_type: 'Checking',
    property_id: this.props.propertyId,
    type: this.props.type
  };

  change({target: {name, value}}) {
    this.setState({[name]: value});
  }

  save() {
    validate(this).then(() => {
      actions.createPayscapeAccount(this.state).then(this.props.toggle);
    });
  }

  render() {
    const {toggle} = this.props;
    const {
      email, phone, business_name, address, city, state, zip, account_name, account_number,
      routing_number, bank_name, account_type, account_ownership_type, ein, cert, term
    } = this.state;
    const change = this.change.bind(this);
    return <Modal isOpen={true} toggle={toggle} size="xl">
      <ModalHeader toggle={toggle}>Create Payscape Account</ModalHeader>
      <ModalBody>
        <Row>
          <Col>
            <div className="labeled-box">
              <ValidatedInput context={this} validation={r => !!r} feedback="Required Field" name="cert"
                              value={cert || ''} onChange={change}/>
              <div className="labeled-box-label">Cert</div>
            </div>
          </Col>
          <Col>
            <div className="labeled-box">
              <ValidatedInput context={this} validation={r => !!r} feedback="Required Field" name="term"
                              value={term || ''} onChange={change}/>
              <div className="labeled-box-label">Term ID</div>
            </div>
          </Col>
        </Row>
        <h3 className="my-3">Business Details</h3>
        <Row>
          <Col>
            <div className="labeled-box">
              <ValidatedInput context={this} validation={r => !!r} feedback="Required Field" name="business_name"
                              value={business_name || ''} onChange={change}/>
              <div className="labeled-box-label">Business Name</div>
            </div>
            <div className="labeled-box mt-3">
              <ValidatedInput context={this} validation={r => !!r} feedback="Required Field" name="email"
                              value={email || ''} onChange={change}/>
              <div className="labeled-box-label">Email</div>
            </div>
            <div className="labeled-box mt-3">
              <ValidatedInput context={this} validation={r => !!r} feedback="Required Field" name="ein"
                              value={ein || ''}
                              onChange={change}/>
              <div className="labeled-box-label">EIN</div>
            </div>
          </Col>
          <Col>
            <div className="labeled-box">
              <ValidatedInput context={this} validation={r => !!r} feedback="Required Field" name="phone"
                              value={phone || ''} onChange={change}/>
              <div className="labeled-box-label">Phone</div>
            </div>

            <div className="labeled-box mt-3">
              <ValidatedInput context={this} validation={r => !!r} feedback="Required Field" name="address"
                              value={address || ''} onChange={change}/>
              <div className="labeled-box-label">Business Address</div>
            </div>
            <Row>
              <Col sm={5}>
                <div className="labeled-box mt-3">
                  <ValidatedInput context={this} validation={r => !!r} feedback="Required Field" name="city"
                                  value={city || ''} onChange={change}/>
                  <div className="labeled-box-label">City</div>
                </div>
              </Col>
              <Col sm={3}>
                <div className="labeled-box mt-3">
                  <ValidatedSelect context={this} validation={r => !!r} feedback="Required Field" options={USSTATES}
                                   name="state" value={state || ''} onChange={change}/>
                  <div className="labeled-box-label">State</div>
                </div>
              </Col>
              <Col sm={4}>
                <div className="labeled-box mt-3">
                  <ValidatedInput context={this} validation={r => !!r} feedback="Required Field" name="zip"
                                  value={zip || ''} onChange={change}/>
                  <div className="labeled-box-label">ZIP</div>
                </div>
              </Col>
            </Row>
          </Col>
        </Row>
        <h3 className="my-3">Bank Details</h3>
        <Row>
          <Col>
            <div className="labeled-box">
              <ValidatedInput context={this} validation={r => !!r} feedback="Required Field" name="bank_name"
                              value={bank_name || ''} onChange={change}/>
              <div className="labeled-box-label">Bank Name</div>
            </div>
            <div className="labeled-box mt-3">
              <ValidatedInput context={this} validation={r => !!r} feedback="Required Field" name="account_number"
                              value={account_number || ''} onChange={change}/>
              <div className="labeled-box-label">Account Number</div>
            </div>
            <div className="labeled-box mt-3">
              <ValidatedInput context={this} validation={r => !!r} feedback="Required Field" name="routing_number"
                              value={routing_number || ''} onChange={change}/>
              <div className="labeled-box-label">Routing Number</div>
            </div>
          </Col>
          <Col>
            <div className="labeled-box">
              <ValidatedInput context={this} validation={r => !!r} feedback="Required Field" name="account_name"
                              value={account_name || ''} onChange={change}/>
              <div className="labeled-box-label">Name On Account</div>
            </div>
            <div className="labeled-box mt-3">
              <ValidatedSelect context={this} validation={r => !!r} feedback="Required Field"
                               options={[{label: 'Business', value: 'Business'}, {
                                 label: 'Personal',
                                 value: 'Personal'
                               }]}
                               name="account_ownership_type" value={account_ownership_type} onChange={change}/>
              <div className="labeled-box-label">Account Ownership Type</div>
            </div>
            <div className="labeled-box mt-3">
              <ValidatedSelect context={this} validation={r => !!r} feedback="Required Field" options={[
                {label: 'Checking', value: 'Checking'},
                {label: 'Savings', value: 'Savings'},
                {label: 'GeneralLedger', value: 'GeneralLedger'}
              ]}
                               name="account_type" value={account_type} onChange={change}/>
              <div className="labeled-box-label">Account Type</div>
            </div>
          </Col>
        </Row>
      </ModalBody>
      <ModalFooter>
        <Button color="success" onClick={this.save.bind(this)}>
          Create Account
        </Button>
      </ModalFooter>
    </Modal>;
  }
}

export default CreatePayscape;