import React, {Component} from 'react';
import moment from "moment";
import {connect} from "react-redux";
import {toCurr, toAccounting} from "../../../utils";

class Account extends Component {
  state = {}

  getMonth(month) {
    const {account, year} = this.props;
    if (account.type === "category") {
      return ""
    } else {
      const b = account.budgets.find(b => moment(b.month).month() === month);
      return b.amount
    }
  }

  getTotal() {
    const {account} = this.props;
    if (account.type === "category") {
      return ""
    } else {
      return this.reduceBudgets(account.budgets)
    }
  }


  reduceBudgets(budgets) {
    return budgets.reduce((acc, b) => b.amount ? acc + parseFloat(b.amount) : acc + 0, 0)
  }

  allLocked() {
    const {account: {budgets}} = this.props;
    if (budgets.length && budgets.length === 12) {
      return budgets.every(b => b.closed && b.closed === true);
    } else {
      return false
    }
  }

  render() {
    const {account, toggle, edit} = this.props;
    return <tr onClick={toggle.bind(this, account)} className={`cursor-pointer ${account.type === "total" ? 'bg-secondary text-white' : ''}`}>
      <td>{account.num}</td>
      <td>{account.name}</td>
      <td>{toAccounting(this.getTotal())}</td>
      <td>{toAccounting(this.getMonth(0))}</td>
      <td>{toAccounting(this.getMonth(1))}</td>
      <td>{toAccounting(this.getMonth(2))}</td>
      <td>{toAccounting(this.getMonth(3))}</td>
      <td>{toAccounting(this.getMonth(4))}</td>
      <td>{toAccounting(this.getMonth(5))}</td>
      <td>{toAccounting(this.getMonth(6))}</td>
      <td>{toAccounting(this.getMonth(7))}</td>
      <td>{toAccounting(this.getMonth(8))}</td>
      <td>{toAccounting(this.getMonth(9))}</td>
      <td>{toAccounting(this.getMonth(10))}</td>
      <td>{toAccounting(this.getMonth(11))}</td>
    </tr>
    // return <tr onClick={toggle.bind(this, account)} className={`cursor-pointer ${account.header ? 'text-primary' : ''}`}>
    //   {edit && !account.header && <td>
    //     <i className={`fas fa-${this.allLocked() ? 'lock' : 'lock-open'}`} />
    //   </td>}
    //   <td>{account.num}</td>
    //   <td>{account.name}</td>
    //   <td>{toCurr(account.header ? this.getHeaderTotal() : this.getTotal())}</td>
    //   <td>{toCurr(this.getMonth(0))}</td>
    //   <td>{toCurr(this.getMonth(1))}</td>
    //   <td>{toCurr(this.getMonth(2))}</td>
    //   <td>{toCurr(this.getMonth(3))}</td>
    //   <td>{toCurr(this.getMonth(4))}</td>
    //   <td>{toCurr(this.getMonth(5))}</td>
    //   <td>{toCurr(this.getMonth(6))}</td>
    //   <td>{toCurr(this.getMonth(7))}</td>
    //   <td>{toCurr(this.getMonth(8))}</td>
    //   <td>{toCurr(this.getMonth(9))}</td>
    //   <td>{toCurr(this.getMonth(10))}</td>
    //   <td>{toCurr(this.getMonth(11))}</td>
    // </tr>
  }
}

export default connect(({budget, year}) => {
  return {budget, year}
})(Account);