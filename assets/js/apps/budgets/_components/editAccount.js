import React, {Component} from 'react';
import {Modal, Row, Button, ModalHeader, ModalBody, Table, Input, ButtonGroup} from 'reactstrap';
import {connect} from "react-redux";
import moment from "moment";
import actions from "../actions";
import {toCurr} from "../../../utils";
import snackbar from '../../../components/snackbar';

class AccountLine extends Component {
  state = {

  }

  changeAmount({target: {value}}) {
    const {line, accumulate} = this.props;
    let params = {amount: value, month: line.month, id: line.id ? line.id : null};
    accumulate(params);
    this.setState({...this.state, amount: value})
  }

  render() {
    const {account, line} = this.props;
    const {amount} = this.state;
    return <tr className={line.closed ? 'alert-danger' : ''}>
      <th>{moment(line.month).format("MMMM")}{line.closed ? <i className="fas fa-lock" /> : <i/>}</th>
      <td>{toCurr(line.amount)}</td>
      <td>
        <div className="labeled-box">
          <Input disabled={line.closed} type="text" value={amount} onChange={this.changeAmount.bind(this)}/>
          <div className="labeled-box-label">New Amount</div>
        </div>
      </td>
      <td>{toCurr(line.accrual)}</td>
      <td></td>
    </tr>
  }
}

class EditAccount extends Component {
  state = {
    acc: []
  }

  constructor(props) {
    super(props);
    const {account, year} = this.props;
    actions.fetchDetailedAccount(year, account.id);
  }

  sortBudgets() {
    const {account, detailedAccount} = this.props;
    const {budgets} = account;
    let new_budgets = [];
    detailedAccount.forEach(a => {
      let month = budgets.filter(b => b.month === a.month)[0];
      if (month) {
        month.accrual = Math.abs(a[account.id]);
        new_budgets.push(month);
      } else {
        month = {}
        month.month = a.month;
        month.accrual = a[account.id];
        month.amount = 0;
        new_budgets.push(month)
      }
    })
    return new_budgets.sort((a, b) => moment(a.month).isBefore(moment(b.month)) ? -1 : 1)
  }

  addToAcc(params) {
    const {acc} = this.state;
    let account = acc.filter(a => a.month === params.month)[0];
    if (account) {
      acc.splice(acc.indexOf(account), 1, params)
    } else {
      acc.push(params)
    }
    this.setState({...this.state, acc: acc})
  }

  lockMonth() {
    const {account, year} = this.props;
    actions.lockAccount({account_id: account.id, year: year})
  }

  saveAcc() {
    const {account} = this.props;
    const {acc} = this.state;
    if (!acc || !acc.length) return snackbar({message: "Nothing To Update", args: {type: 'error'}});
    if (!acc || !acc[0].month) return snackbar({message: "Invalid Month Somehow", args: {type: 'error'}});
    actions.updateLines(account.id, acc)
  }

  render() {
    const {toggle, account} = this.props;
    return <Modal isOpen={true} size="lg" toggle={toggle}>
      <ModalHeader>
        Edit - {account.num} | {account.name}
      </ModalHeader>
      <ModalBody>
        <Row className="d-flex justify-content-end">
          <ButtonGroup className="mr-2">
            {/*<Button  outline color="warning">*/}
              {/*Close Account For The Year*/}
            {/*</Button>*/}
            <Button  onClick={this.saveAcc.bind(this)} outline color="success">
              Save
            </Button>
          </ButtonGroup>
        </Row>
        <Row>
          <Table striped>
            <thead>
              <tr>
                <th>Month</th>
                <th>Current Budget</th>
                <th>New Amount</th>
                <th>Accrued</th>
                <th>Change</th>
              </tr>
            </thead>
            <tbody>
            {this.sortBudgets().map((l, i) => {
              return <AccountLine key={l.id ? l.id : i} account={account} line={l} accumulate={this.addToAcc.bind(this)} />
            })}
            </tbody>
          </Table>
        </Row>
      </ModalBody>
    </Modal>
  }
}

export default connect(({year, detailedAccount}) => {
  return {year, detailedAccount}
})(EditAccount);