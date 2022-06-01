import React, {Component} from 'react';
import {connect} from 'react-redux';
import {Button, Modal, ModalHeader, ModalBody, ModalFooter} from 'reactstrap';
import Person from './person';
import MoveIn from './moveIn';
import PetsVehicles from './petVehicles';
import Histories from './histories';
import Contacts from './contacts';
import Employments from './employments';
import AppModal from './appModal';
import PaymentModal from './paymentModal';
import actions from '../../actions';

const submittingBtn = <button
  className="btn btn-secondary submit-btn d-flex justify-content-center align-items-center"
  disabled
>
  <div className="fas fa-stack">
    <i className="fas fa-circle fa-stack-2x text-primary"/>
    <i className="fas fa-sync fa-spin fa-stack-1x white-text"/>
  </div>
  Submitting...
</button>;

class SubmittingModal extends Component {
  render() {
    return <Modal isOpen={true}>
      <ModalHeader>
        Submitting Your Application
      </ModalHeader>
      <ModalBody>
        <p>Please do not close the browser window until your submission is complete.</p>
      </ModalBody>
    </Modal>
  }
}

class NameInput extends Component {
  constructor(props) {
    super(props);

    this.state = {
      name: '',
      valid: false
    };
  }

  updateName(e) {
    e.target.value === this.props.occupant ? this.props.validation(e.target.value) : null;
    this.setState({...this.state, name: e.target.value});
  }

  render() {
    const {name} = this.state;
    const {occupant, lang} = this.props;
    return <React.Fragment>
      <div className="input-group align-self-start">
        <div className="input-group-prepend">
          <span className="input-group-text">{lang.i}{" "}</span>
        </div>
        <input
          readOnly={name === occupant} type='text'
          placeholder={`Name on Lease (${occupant})`}
          onChange={this.updateName.bind(this)}
          className={`form-control is-${name.trim() === occupant.trim() ? 'valid disabled' : 'invalid'}`}
        />
        <div className="input-group-append">
          <span className='input-group-text'>{lang.name_and_agree_input}.</span>
        </div>
      </div>
    </React.Fragment>
  }
}

class Review extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      arrayOfNames: [],
      newArrayOfNames: [],
      validated: false
    };
  }

  componentWillMount() {
    let newArray = [];
    this.props.application.occupants.map(o => o.status === "Lease Holder" ? newArray.push(o.full_name) : null);
    this.setState({...this.state, arrayOfNames: newArray});
  }

  submit() {
    actions.initializeApplication();
    this.setState(
      {
        ...this.state,
        submitted: true,
        submitting: false,
        paymentModal: false
      }
    );
  }

  saveDateTime() {
    const log = new Date();
    this.setState({
      ...this.state,
      termsAcceptedLog: log,
      paymentModal: !this.state.paymentModal,
      agreeTerms: false,
      newArrayOfNames: [],
      validated: false
    });
  }

  makeValid(dataFromChild) {
    let {newArrayOfNames, arrayOfNames} = this.state;
    if (!newArrayOfNames.includes(dataFromChild)) newArrayOfNames.push(dataFromChild);
    this.setState({
      ...this.state,
      newArrayOfNames: newArrayOfNames,
      validated: arrayOfNames.length === newArrayOfNames.length
    });
  }

  openPayment() {
    this.setState(
      {
        ...this.state,
        paymentModal: !this.state.paymentModal,
        agreeTerms: false
      }
    );
  }

  _termsModal() {
    const close = this.agreeTerms.bind(this);
    const {occupants} = this.props.application;
    const {validated} = this.state;
    return <Modal isOpen={true} className='modal-lg'>
      <ModalHeader toggle={close}>
        {this.props.lang.accept_t_and_c_header}
      </ModalHeader>
      <ModalBody>
        <div dangerouslySetInnerHTML={{__html: window.PROPERTY_TERMS}}/>
      </ModalBody>
      <ModalFooter className='no-end-footer'>
        <div className='row w-100'>
          <div className="col-sm-10 float-left">
            {occupants.map(o => o.status === "Lease Holder" ?
              <NameInput
                key={o._id}
                lang={this.props.lang}
                validation={this.makeValid.bind(this)}
                occupant={o.full_name}
              /> : null)
            }
          </div>
          <a
            className={`col-sm-2 btn btn-success btn-block align-self-start ${validated ? 'valid' : 'disabled'}`}
            onClick={this.saveDateTime.bind(this)}
          >Agree</a>
        </div>
      </ModalFooter>
    </Modal>
  }

  agreeTerms() {
    this.setState(
      {
        ...this.state,
        agreeTerms: !this.state.agreeTerms,
        newArrayOfNames: [],
        validated: false
      }
    );
  }

  // Assuming we have a property URL, redirect there. Otherwise, reset the form
  closeModal() {
    if(this.props?.property?.website) {
      window.location.href = this.props.property.website
    } else {
      this.setState({...this.state, submitted: false});
    }
  }

  updateApplication() {
    this.setState({submitting: true});
    actions.updateApplication().then(() => {
      this.setState({submitting: false});
    })
  }

  _submitBtn() {
    if (actions.validateApplication()) {
      if (window.APPLICATION_JSON) {
        return (
          <button
            className="btn btn-success submit-btn"
            onClick={this.updateApplication.bind(this)}
          >
            <div className="fas fa-stack">
              <i className="fas fa-circle fa-stack-2x text-primary" />
              <i className="fas fa-check fa-stack-1x white-text" />
            </div>
            Update Application
          </button>
        );
      }
      return (
        <button
          className="btn btn-success submit-btn"
          onClick={this.agreeTerms.bind(this)}
        >
          <div className="fas fa-stack">
            <i className="fas fa-circle fa-stack-2x text-primary"/>
            <i className="fas fa-check fa-stack-1x white-text"/>
          </div>
          {this.props.lang.submit_app_button}
        </button>
      );
    }
    return (
      <button className="btn btn-danger submit-btn">
        <div className="fas fa-stack">
          <i className="fas fa-circle fa-stack-2x text-white"/>
          <i className="fas fa-times fa-stack-1x text-danger"/>
        </div>
        {this.props.lang.submit_fix_errors_button}
      </button>
    );
  }

  render() {
    const {application, lang, property} = this.props;
    const {submitting, agreeTerms, paymentModal} = this.state;
    const numAdults = application.occupants.filter(o => o.isAdult()).length;

    return (
      <div className="review-section">
        {agreeTerms && this._termsModal()}
        {paymentModal &&
          <PaymentModal
            close={this.openPayment.bind(this)}
            agreement_text={property.agreement_text}
            numAdults={numAdults}
            appFee={Number(property.application_fee)}
            adminFee={Number(property.admin_fee)}
            cc_processor={property.public_cc_processor}
            onSubmit={this.submit.bind(this)}
            lang={this.props.lang}
          />
        }
        <div className="row">
          <div className="col-md-12">
            <div className="card">
              <div className="card-header">
                {lang.occupants}
              </div>
              <div className="card-body">
                <div className="row">
                  {application.occupants.map(o => <Person key={o._id} lang={lang} person={o}/>)}
                </div>
              </div>
            </div>
          </div>
        </div>
        <div className="row margin-row">
          <div className="col-md-6">
            <MoveIn
              movein={application.move_in}
              lang={lang}
            />
          </div>
          <div className="col-md-6">
            <PetsVehicles
              pets={application.pets}
              lang={lang}
              vehicles={application.vehicles}
            />
          </div>
        </div>
        <div className="row margin-row">
          <div className="col-md-6">
            <Histories
              histories={application.histories}
              lang={lang}
            />
          </div>
          <div className="col-md-6">
            <Contacts
              contacts={application.emergency_contacts}
              lang={lang}
            />
          </div>
        </div>
        <div className="row">
          <div className="col-md-6">
            <Employments
              employments={application.employments}
              income={application.income}
              lang={lang}
            />
          </div>
          <div className="col-md-6 submit-container">
            {submitting ? submittingBtn : this._submitBtn()}
          </div>
        </div>
        {this.state.submitting && <SubmittingModal/>}
        {this.state.submitted &&
          <AppModal heading="Success" close={this.closeModal.bind(this)}/>
        }
      </div>
    );
  }
}

export default connect((s) => {
  return {application: s.application, lang: s.language, property: s.property};
})(Review);
