import React from 'react';
import moment from 'moment';
import {Button, Input, Modal, ModalBody, ModalHeader, ModalFooter, Alert} from 'reactstrap';
import confirmation from '../../../../../components/confirmationModal';
import actions from '../../../actions';
class Locks extends React.Component {
  state = {};

  lockModal() {
    this.setState({modalOpen: !this.state.modalOpen});
  }

  _lockButton() {
    return <Button color="info" onClick={this.lockModal.bind(this)}>
      <i className="fas fa-lock"/> &nbsp;Lock Account
    </Button>
  }

  _unlockButton(activeLock) {
    return <Alert color="danger" className="m-0 py-0 pr-0 d-flex align-items-center">
      <div className="mr-3">User Account locked on {moment(activeLock.inserted_at).format('MM/DD/YYYY')}.
        Reason: {activeLock.reason} Locked by: {activeLock.admin}</div>
      <Button color="info" onClick={this.unlock.bind(this, activeLock)}>
        <i className="fas fa-lock-open"/> &nbsp;Unlock Account
      </Button>
    </Alert>
  }

  unlock(activeLock) {
    confirmation('Unlock this account?').then(() => {
      actions.unlockAccount(activeLock);
    });
  }

  changeReason({target: {value}}) {
    this.setState({reason: value});
  }

  lock() {
    const {account} = this.props;
    const {reason} = this.state;
    actions.lockAccount({account_id: account.id, reason}).then(this.lockModal.bind(this));
  }

  render() {
    const {latestLock} = this.props;
    const {modalOpen, reason} = this.state;
    const toggle = this.lockModal.bind(this);
    return <div>
      {latestLock && latestLock.enabled ? this._unlockButton(latestLock) : this._lockButton()}
      {modalOpen && <Modal isOpen={true} toggle={toggle}>
        <ModalHeader toggle={toggle}>
          Lock Account
        </ModalHeader>
        <ModalBody>
          <div className="labeled-box">
            <Input value={reason || ''} onChange={this.changeReason.bind(this)}/>
            <div className="labeled-box-label">Reason</div>
          </div>
        </ModalBody>
        <ModalFooter>
          <Button onClick={toggle} color="danger" outline>Cancel</Button>
          <Button onClick={this.lock.bind(this)} color="success" disabled={!reason}>
            Lock Account
          </Button>
        </ModalFooter>
      </Modal>}
    </div>
  }
}

export default Locks;