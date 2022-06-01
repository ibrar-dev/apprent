import React, {Component} from "react";
import snackbar from "../../../components/snackbar";
import confirmation from "../../../components/confirmationModal";
import actions from "../actions";
import {Button, Col, Input, Modal, ModalBody, ModalHeader, Row, Table} from "reactstrap";
import FancyCheck from "../../../components/fancyCheck";

class NewAccount extends Component {
  state = {
    name: '',
    num: '',
    charge_code: '',
    is_credit: false,
    is_balance: false,
    is_payable: false,
    is_cash: false,
    source_id: null
  };
  change({target: {name, value}}) {
    this.setState({...this.state, [name]: value})
  }
  changeCheckbox({target: {name}}) {
    const account = this.state;
    let value = !account[name];
    this.setState({...this.state, [name]: value})
  }

  errorMessage(message) {
    return snackbar({
      message: message,
      args: {type: 'error'}
    });
  }

  confirmationSave(message) {
    const account = this.state;
    confirmation(message).then(() => {
      actions.createAccount(account).then(this.props.toggle)
    })
  }

  saveAccount() {
    const {name, num} = this.state;
    if (name.length < 1) return this.errorMessage("Account name is required");
    if (num.length < 1) return this.errorMessage("Account number is required");
    return this.confirmationSave("Please confirm you would like to create this Account");
  }

  render() {
    const {toggle} = this.props;
    const {name, num, charge_code, is_credit, is_balance, is_payable, is_cash} = this.state;
    return <Modal isOpen={true} toggle={toggle}>
      <ModalHeader toggle={toggle}>
        Add Account
      </ModalHeader>
      <ModalBody>
        <Row>
          <Col>
            <div className="labeled-box">
              <Input name="num" value={num} onChange={this.change.bind(this)} />
              <div className="labeled-box-label">Number</div>
            </div>
          </Col>
          <Col>
            <div className="labeled-box">
              <Input name="charge_code" value={charge_code} onChange={this.change.bind(this)} />
              <div className="labeled-box-label">Description</div>
            </div>
          </Col>
        </Row>
        <Row className="mt-2">
          <Col>
            <div className="labeled-box">
              <Input name="name" value={name} onChange={this.change.bind(this)} />
              <div className="labeled-box-label">Name</div>
            </div>
          </Col>
        </Row>
        <Row>
          <Col className="mt-1">
            <Table style={{textAlign: "right"}}>
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
                  <FancyCheck inline value={is_credit} name="is_credit" onChange={this.changeCheckbox.bind(this)} />
                </td>
                <td>
                  <FancyCheck inline value={is_balance} name="is_balance" onChange={this.changeCheckbox.bind(this)} />
                </td>
                <td>
                  <FancyCheck inline value={is_payable} name="is_payable" onChange={this.changeCheckbox.bind(this)} />
                </td>
                <td>
                  <FancyCheck inline value={is_cash} name="is_cash" onChange={this.changeCheckbox.bind(this)} />
                </td>
              </tr>
              </tbody>
            </Table>
          </Col>
        </Row>
        <Row>
          <Col className="d-flex flex-row-reverse mt-1">
            <Button onClick={this.saveAccount.bind(this)} outline color="success" >Save</Button>
          </Col>
        </Row>
      </ModalBody>
    </Modal>
  }
}

export default NewAccount;