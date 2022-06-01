import React from 'react';
import {connect} from 'react-redux';
import actions from '../actions';
import { Button, Modal, ModalHeader, ModalBody, ModalFooter } from 'reactstrap';

class Toolbar extends React.Component {
  constructor(props) {
    super(props);
    this.state = {};
  }

  toggleModal() {
    this.setState({...this.state, saveModal: !this.state.saveModal});
  }

  save() {
    actions.saveForm().then((r) => {
      this.toggleModal();
    });
  }

  render() {
    const {applicant, lang} = this.props;
    const applicantEmailValidation = applicant.email.match(/^.+@[^.].*\.[a-z]{2,}$/);
    const applicantEmail = applicantEmailValidation && applicantEmailValidation[0];
    return<div>
<div className="toolbar d-flex">
      <button className="btn border-right-ac"
              disabled={this.props.currentStage === 0}
              onClick={actions.nextStage.bind(null, -1)}>
        <div className="fas fa-stack">
          <i className="fa fas fa-chevron-left fa-stack-1x"/>
        </div>
        <span>{lang.prev}</span>
      </button>
      <button className="btn border-right-ac"
              onClick={this.toggleModal.bind(this)}>
        {/*<div className="fas fa-stack">*/}
          {/*<i className="fas fa-save fa-stack-1x"/>*/}
        {/*</div>*/}
        <span>{lang.save}</span>
      </button>
      <button className="btn" onClick={actions.nextStage.bind(null, 1)}>
        <span>{lang.next}</span>
        <div className="fas fa-stack">
          <i className="fa fas fa-chevron-right fa-stack-1x"/>
        </div>
      </button>
</div>
      <Modal isOpen={this.state.saveModal} toggle={this.toggleModal.bind(this)}>
        <ModalHeader toggle={this.toggleModal.bind(this)}>
          <div className="fas fa-stack">
            <i className={`fas fa-circle fa-stack-2x text-${applicantEmail ? 'primary' : 'danger'}`}/>
            <i className={`fas fa-${applicantEmail ? 'save' : 'exclamation'} fa-stack-1x white-text`}/>
          </div>
          Save Application Form
        </ModalHeader>
        <ModalBody>
          <p>Your application will be securely saved for you to return and complete it at a later time.</p>
          {applicantEmail && <p>A PIN number will be sent to the Applicant email you entered: {applicantEmail}</p>}
          {!applicantEmail && <p><b>You must enter a valid email address in the "Applicant Information" section in order to save your application.
          </b></p>}
        </ModalBody>
        <ModalFooter>
          <Button color="primary" onClick={this.toggleModal.bind(this)}>Cancel</Button>{' '}
          {applicantEmail && <Button color="success" onClick={this.save.bind(this)}>{lang.save}</Button>}
        </ModalFooter>
      </Modal>
</div>

  }
}

export default connect((s) => {
  return {applicant: s.application.occupants.models[0], lang: s.language};
})(Toolbar);