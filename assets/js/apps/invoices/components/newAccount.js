import React from 'react';
import {Modal, ModalHeader, ModalBody, ModalFooter, Button, Table} from 'reactstrap';
import {ValidatedInput, validate} from "../../../components/validationFields";
import {capitalize} from "../../../utils";
import actions from '../actions';

class NewAccount extends React.Component {
  state = {is_credit: false, is_balance: false};

  change({target: {name, value, type}}) {
    const val = type === 'text' ? value : eval(value);
    this.setState({[name]: val});
  }

  save() {
    validate(this).then(() => {
      const {toggle, accountType} = this.props;
      actions.createAccount({...this.state, [accountType]: true}).then(toggle);
    });
  }

  render() {
    const {toggle, accountType} = this.props;
    const {name, is_credit, is_balance} = this.state;
    const change = this.change.bind(this);
    return <Modal isOpen={true} toggle={toggle} size="lg">
      <ModalHeader toggle={toggle}>Create New {capitalize(accountType.replace('is_', ''))} Account</ModalHeader>
      <ModalBody>
        <Table className="m-0">
          <tbody>
          <tr>
            <td className="border-0">
              <ValidatedInput context={this}
                              validation={v => !!v}
                              feedback="Enter account name"
                              value={name || ''} onChange={this.change.bind(this)} name="name"/>
            </td>
            <td className="min-width border-top-0">
              <label className="d-flex align-items-center nowrap m-0">
                <input type="radio" name="is_credit" checked={is_credit} onChange={change} value={true}/>
                <div className="mx-1">Credit</div>
              </label>
              <label className="d-flex align-items-center nowrap m-0">
                <input type="radio" name="is_credit" checked={!is_credit} onChange={change} value={false}/>
                <div className="ml-1">Debit</div>
              </label>
            </td>
            <td className="min-width border-top-0">
              <label className="d-flex align-items-center nowrap m-0">
                <input type="radio" name="is_balance" checked={is_balance} onChange={change} value={true}/>
                <div className="ml-1">Balance</div>
              </label>
              <label className="d-flex align-items-center nowrap m-0">
                <input type="radio" name="is_balance" checked={!is_balance} onChange={change} value={false}/>
                <div className="ml-1">Income</div>
              </label>
            </td>
          </tr>
          </tbody>
        </Table>
      </ModalBody>
      <ModalFooter>
        <Button color="success" onClick={this.save.bind(this)}>
          Create
        </Button>
      </ModalFooter>
    </Modal>;
  }
}

export default NewAccount;