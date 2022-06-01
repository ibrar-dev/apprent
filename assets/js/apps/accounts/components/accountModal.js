import React, {Component} from "react";
import {Button, Col, Input, Modal, ModalBody, ModalHeader, Row, Table} from "reactstrap";
import snackbar from "../../../components/snackbar";
import actions from "../actions";
import FancyCheck from "../../../components/fancyCheck";
import Select from '../../../components/select';

class NewAccount extends Component {
  state = {...this.props.account};

  change({target: {name, value}}) {
    this.setState({[name]: value})
  }

  changeCheckbox({target: {name}}) {
    const account = this.state;
    let value = !account[name];
    this.setState({[name]: value})
  }

  errorMessage(message) {
    return snackbar({
      message: message,
      args: {type: 'error'}
    });
  }

  saveAccount() {
    const {name, num} = this.state;
    if (name.length < 1) return this.errorMessage("Account name is required");
    if (num.length < 1) return this.errorMessage("Account number is required");
    actions.updateAccount(this.state).then(this.props.toggle);
  }

  deleteAccount() {
    const {account, toggle} = this.props;
    if (confirm('Delete this account?')) {
      actions.deleteAccount(account.id).then(toggle);
    }
  }

  render() {
    const {toggle, categories} = this.props;
    const {name, num, charge_code, is_credit, is_balance, is_payable, is_cash, source_id, external_id} = this.state;
    const sourceOptions = categories.map(c => ({label: c.name, value: c.id}));
    sourceOptions.unshift({label: 'NONE', value: null});
    return <Modal isOpen={true} toggle={toggle}>
      <ModalHeader toggle={toggle}>
        Update Account
      </ModalHeader>
      <ModalBody>
        <Row>
          <Col>
            <div className="labeled-box">
              <Input name="num" value={num || ''} onChange={this.change.bind(this)}/>
              <div className="labeled-box-label">Number</div>
            </div>
          </Col>
          <Col>
            <div className="labeled-box">
              <Input name="charge_code" value={charge_code || ''} onChange={this.change.bind(this)}/>
              <div className="labeled-box-label">Description</div>
            </div>
          </Col>
        </Row>
        <div className="labeled-box mt-2">
          <Input name="name" value={name || ''} onChange={this.change.bind(this)}/>
          <div className="labeled-box-label">Name</div>
        </div>
        <Row>
          <Col>
            <div className="labeled-box mt-2">
              <Select options={sourceOptions} name="source_id" value={source_id || ''}
                      onChange={this.change.bind(this)}/>
              <div className="labeled-box-label">Source Category</div>
            </div>
          </Col>
          <Col>
            <div className="labeled-box mt-2">
              <Input name="external_id" value={external_id || ''} onChange={this.change.bind(this)}/>
              <div className="labeled-box-label">External ID</div>
            </div>
          </Col>
        </Row>
        <Row>
          <Col className="mt-1">
            <Table className="text-center">
              <thead>
              <tr>
                <th>Credit</th>
                <th>Balance</th>
                <th>Payable</th>
                <th>Cash</th>
              </tr>
              </thead>
              <tbody>
              <tr>
                <td>
                  <FancyCheck inline checked={is_credit} name="is_credit" onChange={this.changeCheckbox.bind(this)}/>
                </td>
                <td>
                  <FancyCheck inline checked={is_balance} name="is_balance" onChange={this.changeCheckbox.bind(this)}/>
                </td>
                <td>
                  <FancyCheck inline checked={is_payable} name="is_payable" onChange={this.changeCheckbox.bind(this)}/>
                </td>
                <td>
                  <FancyCheck inline checked={is_cash} name="is_cash" onChange={this.changeCheckbox.bind(this)}/>
                </td>
              </tr>
              </tbody>
            </Table>
          </Col>
        </Row>
        <Row>
          <Col className="d-flex justify-content-between mt-1">
            <Button onClick={this.deleteAccount.bind(this)} color="danger">Delete</Button>
            <Button onClick={this.saveAccount.bind(this)} color="success">Save</Button>
          </Col>
        </Row>
      </ModalBody>
    </Modal>
  }
}

export default NewAccount;