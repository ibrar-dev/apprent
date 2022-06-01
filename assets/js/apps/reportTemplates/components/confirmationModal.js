import React, {Component} from 'react';
import {Modal, ModalHeader, ModalBody, Row, Col, Input, ModalFooter, Button} from 'reactstrap';
import actions from '../actions';

class ConfirmationModal extends Component {
  state = {}

  componentWillMount() {
    const {accounts, changedAccounts} = this.props;
    let newChangedAccounts = [];
    changedAccounts.forEach(a => {
      let account = accounts.filter(acc => acc.id === a)[0];
      account.confirmed = false;
      account.changed = false;
      newChangedAccounts.push(account);
    });
    this.setState({...this.state, newChangedAccounts})
  }

  change(id, {target: {name, value}}) {
    const {newChangedAccounts} = this.state;
    let account = newChangedAccounts.filter(a => a.id === id)[0];
    account[name] = value;
    account.changed = true;
    newChangedAccounts.splice(newChangedAccounts.indexOf(account), 1, account);
    this.setState({...this.state, newChangedAccounts});
  }

  changeRadio(id, type, {target: {value}}) {
    const {newChangedAccounts} = this.state;
    let account = newChangedAccounts.filter(a => a.id === id)[0];
    account[type] = eval(value);
    account.changed = true;
    newChangedAccounts.splice(newChangedAccounts.indexOf(account), 1, account);
    this.setState({...this.state, newChangedAccounts});
  }

  changeCheckbox(id, {target: {name, value}}) {
    const {newChangedAccounts} = this.state;
    let account = newChangedAccounts.filter(a => a.id === id)[0];
    account[name] = !eval(value);
    account.changed = true;
    newChangedAccounts.splice(newChangedAccounts.indexOf(account), 1, account);
    this.setState({...this.state, newChangedAccounts});
  }

  confirmSave(id) {
    const {newChangedAccounts} = this.state;
    let account = newChangedAccounts.filter(a => a.id === id)[0];
    if (account.changed) {
      actions.updateAccount(account).then(() => {
        account.confirmed = true;
        newChangedAccounts.splice(newChangedAccounts.indexOf(account), 1, account);
        this.setState({...this.state, newChangedAccounts});
      }).catch(() => {
        account.confirmed = true;
        newChangedAccounts.splice(newChangedAccounts.indexOf(account), 1, account);
        this.setState({...this.state, newChangedAccounts});
      })
    } else {
      account.confirmed = true;
      newChangedAccounts.splice(newChangedAccounts.indexOf(account), 1, account);
      this.setState({...this.state, newChangedAccounts});
    }
  }

  canSaveTemplate() {
    const {newChangedAccounts} = this.state;
    return newChangedAccounts.every(a => a.confirmed)
  }

  render() {
    const {toggle, save} = this.props;
    const {newChangedAccounts} = this.state;
    return <Modal isOpen={true} toggle={toggle} size="lg">
      <ModalHeader toggle={toggle}>
        <div className="d-flex flex-column">
          <span>You changed {newChangedAccounts.length} {newChangedAccounts.length > 1 ? 'accounts' : 'account'}.</span>
          <span>Please make any account changes below.</span>
        </div>
      </ModalHeader>
      <ModalBody>
        {newChangedAccounts.length && newChangedAccounts.map(a => {
          return <Row key={a.id}>
            <Col className="d-flex justify-content-between border">
              <div className="labeled-box mt-1 w-25">
                <Input disabled={a.confirmed} onChange={this.change.bind(this, a.id)} value={a.num || ""} name="num" />
                <div className="labeled-box-label">Number</div>
              </div>
              <div className="labeled-box mt-1 w-40">
                <Input disabled={a.confirmed} onChange={this.change.bind(this, a.id)} value={a.name} name="name" />
                <div className="labeled-box-label">Name</div>
              </div>
              <div className="w-10">
                <label className="d-flex align-items-center nowrap m-0">
                  <input disabled={a.confirmed} type="radio" name={`is_credit_${a.id}`} checked={a.is_credit} onChange={this.changeRadio.bind(this, a.id, "is_credit")} value={true}/>
                  <div className="mx-1">Credit</div>
                </label>
                <label className="d-flex align-items-center nowrap m-0">
                  <input disabled={a.confirmed} type="radio" name={`is_credit_${a.id}`} checked={!a.is_credit} onChange={this.changeRadio.bind(this, a.id, "is_credit")} value={false}/>
                  <div className="ml-1">Debit</div>
                </label>
              </div>
              <div className="w-10">
                <label className="d-flex align-items-center nowrap m-0">
                  <input disabled={a.confirmed} type="radio" name={`is_balance_${a.id}`} checked={a.is_balance} onChange={this.changeRadio.bind(this, a.id, "is_balance")} value={true}/>
                  <div className="mx-1">Credit</div>
                </label>
                <label className="d-flex align-items-center nowrap m-0">
                  <input disabled={a.confirmed} type="radio" name={`is_balance_${a.id}`} checked={!a.is_balance} onChange={this.changeRadio.bind(this, a.id, "is_balance")} value={false}/>
                  <div className="ml-1">Debit</div>
                </label>
              </div>
              <div className="w-10">
                <label className="d-flex align-items-center nowrap m-0">
                  <input disabled={a.confirmed} type="checkbox" name="is_cash" checked={a.is_cash} onChange={this.changeCheckbox.bind(this, a.id)} value={a.is_cash} />
                  <div className="mx-1">Cash</div>
                </label>
                <label className="d-flex align-items-center nowrap m-0">
                  <input disabled={a.confirmed} type="checkbox" name="is_payable" checked={a.is_payable} onChange={this.changeCheckbox.bind(this, a.id)} value={a.is_payable} />
                  <div className="mx-1">Payable</div>
                </label>
              </div>
              <div className="d-flex align-items-center w-5" onClick={this.confirmSave.bind(this, a.id)}>
                {!a.confirmed && <i className={`fas fa-${a.changed ? 'save' : 'check'}`} />}
                {a.confirmed && <i className="fas fa-check-square" />}
              </div>
            </Col>
          </Row>
        })}
      </ModalBody>
      <ModalFooter>
        <Button disabled={!this.canSaveTemplate()} onClick={save} color="success">
          Save
        </Button>
      </ModalFooter>
    </Modal>
  }
}

export default ConfirmationModal;