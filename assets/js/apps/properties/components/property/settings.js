import React from 'react';
import {connect} from 'react-redux';
import {Row, Col, Input, Button, Tooltip} from 'reactstrap';
import actions from "../../actions";
import TextEditModal from '../textEditModal';
import FancyCheck from '../../../../components/fancyCheck';
import Select from '../../../../components/select';
import canEdit from '../../../../components/canEdit';
import tooltips from './tooltips';

class ToolTipItem extends React.Component {
  state = {isOpen: false};

  toggle() {
    this.setState({...this.state, isOpen: !this.state.isOpen});
  }

  render() {
    return (
      <Tooltip isOpen={this.state.isOpen} target={`${this.props.id}`} toggle={this.toggle.bind(this)}>
        {this.props.content}
      </Tooltip>
    )
  }
}

class Settings extends React.Component {
  state = {settings: this.props.property.settings, bankAccounts: []};

  static getDerivedStateFromProps(props) {
    return {settings: props.property.settings};
  }

  toggleEditMode() {
    const {settings, editMode} = this.state;
    if (editMode) actions.updateProperty({id: this.props.property.id, settings});
    this.setState({editMode: !this.state.editMode});
  }

  fieldFrame(label, fieldName, element) {
    return <Row className="mb-2 d-flex justify-content-between">
      <Col sm={3} className="d-flex align-items-center">
        {label}
      </Col>
      <Col className="d-flex align-items-center">
        {element}
        <i id={`more_info_${fieldName}`} className="fas fa-question cursor-pointer ml-2"/>
      </Col>
    </Row>;
  }

  fieldFor(label, fieldName) {
    const {settings, editMode} = this.state;
    const element = <Input value={settings[fieldName] || ''}
                           disabled={!editMode}
                           placeholder={'Enter ' + label}
                           name={fieldName}
                           type="number"
                           onChange={this.change.bind(this)}/>;
    return this.fieldFrame(label, fieldName, element);
  }

  selectFieldFor(label, fieldName, options) {
    const {settings, editMode} = this.state;
    const element = <Select value={settings[fieldName] || ''}
                            disabled={!editMode}
                            className="flex-auto"
                            placeholder={'Enter ' + label}
                            name={fieldName}
                            options={options}
                            onChange={this.change.bind(this)}/>;
    return this.fieldFrame(label, fieldName, element);
  }

  toggleFieldFor(label, fieldName) {
    const {settings, editMode} = this.state;
    const element = <div className="flex-auto">
      <FancyCheck inline disabled={!editMode} name={fieldName} checked={settings[fieldName]}
                  value={settings[fieldName]} onChange={this.toggle.bind(this, settings[fieldName])}/>
    </div>;
    return this.fieldFrame(label, fieldName, element);
  }

  change({target: {name, value}}) {
    const {settings} = this.state;
    settings[name] = value;
    this.setState({...this.state, settings});
  }

  toggle(currentVal, {target: {name}}) {
    const {settings} = this.state;
    settings[name] = !currentVal;
    this.setState({...this.state, settings})
  }

  _late_fee() {
    const {settings, editMode} = this.state;
    return <Row className="mb-2 d-flex justify-content-between">
      <Col sm={3} className="d-flex align-items-center">
        Late Fee
      </Col>
      <Col>
        <Input value={settings.late_fee_amount || ''}
               disabled={!editMode}
               placeholder={'Enter Late Fee Amount'}
               name="late_fee_amount"
               type="number"
               onChange={this.change.bind(this)}/>
      </Col>
      <Col>
        <Input value={settings.late_fee_type || ''} disabled={!editMode} name="late_fee_type" type="select"
               onChange={this.change.bind(this)}>
          <option/>
          <option value="%">%</option>
          <option value="$">$</option>
        </Input>
      </Col>
      <i id={`more_info_late_fee`} className="fas fa-question cursor-pointer"/>
    </Row>;
  }

  terms() {
    this.setState({...this.state, termsOpen: !this.state.termsOpen});
  }

  verificationForm() {
    this.setState({...this.state, verificationForm: !this.state.verificationForm})
  }

  paymentAgreementForm() {
    this.setState({...this.state, paymentAgreementForm: !this.state.paymentAgreementForm})
  }
  render() {
    const {property, bankAccounts} = this.props;
    const {editMode, termsOpen, verificationForm, paymentAgreementForm} = this.state;
    return <div>
      <Row>
        <Col sm={11}>
          <Row>
            <Col sm={12} className="d-flex justify-content-between">
              <h3>General</h3>
              <div className="btn-group">
                <Button className="mr-2" color="info" onClick={this.toggleEditMode.bind(this)}>
                  {editMode ? 'Save' : 'Edit'}
                </Button>
                <Button className="mr-2" color="info" onClick={this.verificationForm.bind(this)}>
                  Rental Verification Form
                </Button>
                <Button className="mr-2" color="info" onClick={this.terms.bind(this)}>
                  Terms
                </Button>
                <Button className="mr-2" color="info" onClick={this.paymentAgreementForm.bind(this)}>
                  Payment Agreement Form
                </Button>
              </div>
            </Col>
          </Row>
          <div className="ml-3 pt-1">
            <h4>Misc</h4>
            <hr/>
            {this.toggleFieldFor('Active Property', 'active')}
          </div>
          <div className="ml-3">
            <h4>Applications</h4>
            <hr/>
            {this.toggleFieldFor('Accepting Applications', 'applications')}
            {this.fieldFor('Application Fee', 'application_fee')}
            {this.fieldFor('Admin Fee', 'admin_fee')}
            {this.toggleFieldFor('Instant Screen', 'instant_screen')}
            {this.toggleFieldFor('Confidential Info Visible', 'applicant_info_visible')}
            {this.toggleFieldFor('Accepting Tours', 'tours')}
          </div>
          <div className="ml-3">
            <h4>Payments</h4>
            <hr/>
            {this.fieldFor('NSF Fee', 'nsf_fee')}
            {this.toggleFieldFor('Accept Partial Payments', 'accepts_partial_payments')}
            {this.selectFieldFor('Bank Account For E-Payments', 'default_bank_account_id', bankAccounts.map(s => ({
              label: s.name,
              value: s.id
            })))}
          </div>
          <div className="ml-3">
            <h4>Units</h4>
            <hr/>
            {this.fieldFor('Rate per SqFt', 'area_rate')}
          </div>
          <div className="ml-3">
            <h4>Renewals</h4>
            <hr/>
            {this.fieldFor('Notice Period', 'notice_period')}
            {this.fieldFor('Renewal Percentage Overage', 'renewal_overage_threshold')}
          </div>
          <div className="ml-3">
            <h4>Month to Month</h4>
            <hr/>
            {this.fieldFor('MTM Multiplier', 'mtm_multiplier')}
            {this.fieldFor('MTM Fee', 'mtm_fee')}
          </div>
          <div className="ml-3">
            <h4>Late Fees</h4>
            <hr/>
            {this.fieldFor('Grace Period', 'grace_period')}
            {this.fieldFor('Late Fee Threshold', 'late_fee_threshold')}
            {this._late_fee()}
            {this.fieldFor('Daily Addition', 'daily_late_fee_addition')}
          </div>
        </Col>
        {verificationForm && <TextEditModal property={property} name={"Rental Form"} content={property.settings.verification_form} close={this.verificationForm.bind(this)}/>}
        {paymentAgreementForm && <TextEditModal property={property} name={"Payment Agreement Form"} content={property.settings.agreement_text} close={this.paymentAgreementForm.bind(this)}/>}
        {termsOpen && <TextEditModal property={property} name={"Terms"} content={property.terms} pdf={true} close={this.terms.bind(this)}/>}
      </Row>
      {tooltips.map(t => {
        return <ToolTipItem key={t.id} id={t.id} content={t.content}/>
      })}
    </div>
  }
}

export default connect(({bankAccounts}) => ({bankAccounts}))(Settings);