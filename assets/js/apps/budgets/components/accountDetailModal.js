import React, {Component} from 'react';
import {Modal, ModalHeader, ModalBody, Table} from 'reactstrap';
import moment from 'moment';
import {toAccounting, toPercent} from "../../../utils";

class AccountDetailedModal extends Component {
  state = {};

  determineClass(budget, actual) {
    const {budgetLine} = this.props;
    if (budgetLine.is_credit) {
      return actual >= budget ? 'success' : 'danger';
    } else {
      return actual >= budget ? 'danger' : 'success';
    }
  }

  render() {
    const {toggle, budgetLine, details} = this.props;
    const total = details[details.length - 1];
    return <Modal isOpen={true} toggle={toggle} size="lg">
      <ModalHeader toggle={toggle}>
        <span>{budgetLine.num} | {budgetLine.name}</span>
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
          {details.slice(0, 11).map((a, i) => {
            const {actual, budgeted, variance, percent_variance} = a;
            return <tr key={i}>
              <td>{moment(`2000-${('0' + (i + 1)).substr(-2)}-01`).format("MMMM")}</td>
              <td/>
              <td>{toAccounting(actual)}</td>
              <td>{toAccounting(budgeted)}</td>
              <td>{toAccounting(variance)}</td>
              <td className={`alert-${this.determineClass(budgeted, actual)}`}>
                {toPercent(percent_variance)}
              </td>
            </tr>
          })}
          <tr>
            <th>Total</th>
            <th/>
            <th>{toAccounting(total.actual)}</th>
            <th>{toAccounting(total.budgeted)}</th>
            <th>{toAccounting(total.variance)}</th>
            <th className={`alert-${this.determineClass(total.budgeted, total.actual)}`}>
              {toPercent(total.percent_variance)}
            </th>
          </tr>
          </tbody>
        </Table>
      </ModalBody>
    </Modal>
  }
}

export default AccountDetailedModal