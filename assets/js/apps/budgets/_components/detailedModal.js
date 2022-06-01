import React, {Component} from 'react';
import {Modal, ModalHeader, ModalBody, Table} from 'reactstrap';
import moment from 'moment';
import {connect} from "react-redux";
import actions from '../actions';
import {toAccounting, toPercent} from "../../../utils";

class DetailedModal extends Component {
  state = {};

  constructor(props) {
    super(props);
    const {account, year} = this.props;
    actions.fetchDetailedAccount(year, account.num);
    // account.header ? actions.fetchDetailedCategory(year, account.category_id) : actions.fetchDetailedAccount(year, account.num);
  }


  calculateVariance(budgeted, actual) {
    const {account: {is_credit}} = this.props;
    return is_credit ? (actual - budgeted) : (budgeted - actual)
  }

  calculateVariancePercent(budgeted, variance) {
    const percent = (variance / budgeted) * 100;
    return percent ? percent : "N/A"
  }

  calculateTotals() {
    const {detailedAccount} = this.props;
    const budgeted = detailedAccount.reduce((acc, b) => acc + b.stats.ptd_budgeted, 0);
    const actual = detailedAccount.reduce((acc, b) => acc + b.stats.ptd_actual, 0);
    const variance = this.calculateVariance(budgeted, actual);
    const varPercent = this.calculateVariancePercent(budgeted, variance);
    return {budgeted: budgeted, actual: actual, variance: variance, varPercent: varPercent}
  }

  determineClass(budget, actual) {
    const {account} = this.props;
    if (account.is_credit) {
      return actual >= budget ? 'success' : 'danger';
    } else {
      return actual >= budget ? 'danger' : 'success';
    }
  }

  render() {
    const {toggle, account, detailedAccount} = this.props;
    const {budgeted, actual, variance, varPercent} = this.calculateTotals();
    return <Modal isOpen={true} toggle={toggle} size="lg">
      <ModalHeader toggle={toggle}>
        <span>{account.num} | {account.name}</span>
      </ModalHeader>
      <ModalBody>
        <Table borderless striped>
          <thead>
          <tr>
            <th>Month</th>
            <th>Previous Year</th>
            <th>Actual</th>
            <th>Budgeted</th>
            <th>Variance</th>
            <th>Variance %</th>
          </tr>
          </thead>
          <tbody>
          {detailedAccount.map(a => {
            const {ptd_budgeted, ptd_actual, ptd_variance, ptd_variance_percentage} = a.stats;
            return <tr key={a.month}>
              <td>{moment(a.month).format("MMMM")}</td>
              <td/>
              <td className="text-right">{toAccounting(ptd_actual)}</td>
              <td className="text-right">{toAccounting(ptd_budgeted)}</td>
              <td className="text-right">{toAccounting(ptd_variance)}</td>
              <td className={`text-right alert-${this.determineClass(ptd_budgeted, ptd_actual)}`}>{toPercent(ptd_variance_percentage)}</td>
            </tr>
          })}
          <tr>
            <th>Total</th>
            <th className="text-right"/>
            <th className="text-right">{toAccounting(actual)}</th>
            <th className="text-right">{toAccounting(budgeted)}</th>
            <th className="text-right">{toAccounting(variance)}</th>
            <th className={`text-right alert-${this.determineClass(budgeted, actual)}`}>{toPercent(varPercent)}</th>
          </tr>
          </tbody>
        </Table>
      </ModalBody>
    </Modal>
  }
}

export default connect(({detailedAccount, year, budget}) => {
  return {detailedAccount, year, budget}
})(DetailedModal)