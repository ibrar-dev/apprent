import React from 'react';
import {Button, Modal, ModalHeader, ModalBody, Tooltip, ModalFooter} from 'reactstrap';
import actions from '../actions';
import {connect} from 'react-redux';
import DeclineModal from "./declineModal";
import ApprovalModal from './approvalModal';
import ScreeningModal from "./screeningModal";
import MemoModal from './memoModal';

class StatusSelect extends React.Component {
  state = {declined_reason: ''};

  componentDidMount() {
    this._isMounted = true;
  }

  componentWillUnmount() {
    this._isMounted = false;
  }

  toggleModal(modal) {
    this.setState({modal})
  }

  toggleTooltip(buttonName) {
    if (this._isMounted) this.setState({tooltip: this.state.tooltip === buttonName ? null : buttonName});
  }

  getPaymentUrl() {
    actions.getPaymentUrl(this.props.application.id).then(r => {
      this.setState({paymentUrl: r.data.url});
    })
  }

  sendPaymentUrl() {
    actions.sendPaymentUrl(this.props.application.id).then(() => {
      this.setState({paymentSent: true})
    })
  }

  render() {
    const {history, application: {id, full, approval_params, status, unit, persons, property: {id: propertyId}}} = this.props;
    const {modal, tooltip, paymentUrl, paymentSent} = this.state;
    const finished = ['approved', 'declined'].includes(status);
    const approvalText = approval_params.start_date ? 'View-Approval' : 'Approve';
    const buttons = ['View', 'Memo'];
    if (!finished && full === 'true') {
      buttons.push('Decline');
      if (status !== 'submitted' && persons[0].screening_status) buttons.push('Screening-Status');
      if (status === 'signed') buttons.push('Payment-URL');
    }
    return <React.Fragment>
      <Button color="info" outline onClick={() => history.push(`/applications/${id}`, {})} id={`View-btn-${id}`}>
        <i className="fas fa-eye"/>
      </Button>
      <Button color="info" outline onClick={this.toggleModal.bind(this, 'memo')} id={`Memo-btn-${id}`}>
        <i className="fas fa-pen"/>
      </Button>
      {!finished && full === 'true' && <>
        <Button color="info" outline onClick={this.toggleModal.bind(this, 'decline')} id={`Decline-btn-${id}`}>
          <i className="fas fa-window-close"/>
        </Button>
        {status !== 'submitted' && persons[0].screening_status &&
        <Button color="info" outline onClick={this.toggleModal.bind(this, 'screen')} id={`Screening-Status-btn-${id}`}>
          <i className="fas fa-search"/>
        </Button>}
        {approvalText === 'View-Approval' &&
        <Button color="info" outline onClick={this.toggleModal.bind(this, 'approve')} id={`${approvalText}-btn-${id}`}>
          <i className="fas fa-check-circle"/>
        </Button>}
      </>}
      {/*{!finished && full === 'true' && status === 'signed' && <>*/}
        <Button color="info" outline onClick={this.getPaymentUrl.bind(this)} id={`Payment-URL-btn-${id}`}>
          <i className="fas fa-credit-card"/>
        </Button>
      {/*</>}*/}
      {buttons.map(button => <Tooltip key={button} placement="top" isOpen={tooltip === button}
                                      target={`${button}-btn-${id}`}
                                      delay={{show: 0, hide: 0}}
                                      trigger="hover"
                                      toggle={this.toggleTooltip.bind(this, button)}>
        {button.replace('-', ' ')}
      </Tooltip>)}
      {modal === 'approve' && <ApprovalModal unit={unit}
                                             params={approval_params}
                                             persons={persons}
                                             toggle={this.toggleModal.bind(this)}
                                             applicationId={id}
                                             propertyId={propertyId}/>}
      {modal === 'screen' && <ScreeningModal persons={persons.filter(p => p.status === 'Lease Holder')}
                                             toggle={this.toggleModal.bind(this)}
                                             applicationId={id}/>}
      {modal === 'decline' && <DeclineModal toggle={this.toggleModal.bind(this)}
                                            applicationId={id}/>}
      {modal === 'memo' && <MemoModal toggle={this.toggleModal.bind(this)} applicationId={id}/>}
      <Modal isOpen={!!paymentUrl} toggle={() => this.setState({paymentUrl: null})}>
        <ModalHeader toggle={() => this.setState({paymentUrl: null})}>Payment URL</ModalHeader>
        <ModalBody>
          <p>
            <a href={paymentUrl} target="_blank">Administration Fee Payment Form</a>
          </p>
          <hr/>
          <p>Click the "Email Applicant" button below to have AppRent email the applicant with a link to pay the Administration Fee. This will allow applicants to pay the Admin Fee online.</p>
          {paymentSent && <p>Email sent to the applicant. If there are multiple applicants only one of them was notified. You can click above to be taken to the payment link.</p>}
        </ModalBody>
        <ModalFooter>
          <Button color="info" outline onClick={this.sendPaymentUrl.bind(this)}>Email Applicant</Button>
        </ModalFooter>
      </Modal>
    </React.Fragment>;
  }
}

export default connect(({credentialsList}) => {
  return {screenList: credentialsList.screen_creds};
})(StatusSelect);
