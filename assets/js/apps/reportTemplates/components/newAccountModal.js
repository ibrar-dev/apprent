import React from 'react';
import {Input, Modal, ModalHeader, ModalBody, ModalFooter, Button, Table} from 'reactstrap';
import actions from '../actions';

class NewAccountModal extends React.Component {
  state = {
    is_balance: this.props.template.name === 'Balance Sheet',
    is_credit: false,
    is_payable: false,
    is_cash: false,
    name: ''
  };

  createAccount() {
    const {toggle, onCreate} = this.props;
    actions.createAccount(this.state).then(r => {
      actions.fetchAccounts().then(() => {
        onCreate({id: r.data.account.id});
        toggle();
      });
    });
  }

  change({target: {name, value, checked, type}}) {
    const val = type === 'text' ? value : (type === 'radio' ? eval(value) : checked);
    this.setState({[name.replace(/(is_.*)_.*/, '$1')]: val});
  }

  render() {
    const {name, is_credit, is_cash, is_payable} = this.state;
    const {toggle} = this.props;
    const change = this.change.bind(this);
    return <Modal isOpen={true} toggle={toggle}>
      <ModalHeader toggle={toggle}>New Account</ModalHeader>
      <ModalBody>
        <Table className="m-0">
          <tbody>
          <tr>
            <td className="align-middle border-0">
              <Input value={name} onChange={change} name="name"/>
            </td>
            <td className="align-middle min-width border-0">
              <label className="d-flex align-items-center nowrap m-0">
                <input type="radio" name="is_credit" checked={is_credit} onChange={change} value={true}/>
                <div className="mx-1">Credit</div>
              </label>
              <label className="d-flex align-items-center nowrap m-0">
                <input type="radio" name="is_credit" checked={!is_credit} onChange={change} value={false}/>
                <div className="ml-1">Debit</div>
              </label>
            </td>
            <td className="align-middle min-width border-0">
              <label className="d-flex align-items-center nowrap m-0">
                <input type="checkbox" name="is_cash" checked={is_cash} onChange={change} value={true}/>
                <div className="ml-1">Cash</div>
              </label>
              <label className="d-flex align-items-center nowrap m-0">
                <input type="checkbox" name="is_payable" checked={is_payable} onChange={change} value={false}/>
                <div className="ml-1">Payable</div>
              </label>
            </td>
          </tr>
          </tbody>
        </Table>
      </ModalBody>
      <ModalFooter>
        <Button color="success" onClick={this.createAccount.bind(this)}>
          Create Account
        </Button>
      </ModalFooter>
    </Modal>;
  }
}

export default NewAccountModal;