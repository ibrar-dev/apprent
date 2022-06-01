import React, {Component} from "react";
import {toAccounting} from "../../../../utils";
import AccountDetails from "../report/accountDetail";
import moment from "moment";

class MultiMonthAccount extends Component {
  state = {};

  openDetails(month) {
    this.setState({details: !this.state.details, currentMonth: month});
  }

  extractNameAndNum() {
    const {account} = this.props;
    const num = account[0];
    const name = account[1];
    const accountId = account[2];
    return {num: num, name: name, accountId: accountId}
  }

  extractMonths() {
    const {account} = this.props;
    return account.slice(3)
  }

  render() {
    const {details, currentMonth} = this.state;
    const {level, months, account} = this.props;
    if (account.name) {
      return <tr>
        <th colSpan={2} style={{paddingLeft: (level * 15) + 5}}>
          <span>Total {account.name}:</span>
        </th>
        {account.totals.map((m, i) => {
          return <th key={i} className="text-center border-top border-bottom">{toAccounting(m)}</th>
        })}
      </tr>;
    }
    const {num, name, accountId} = this.extractNameAndNum();
    return <tr>
      <td colSpan={2} style={{paddingLeft: (level * 15) + 5}}>
        {num} - {name}
      </td>
      {this.extractMonths().map((m, i) => {
        return <td key={i} className="text-center">
          <a onClick={months[i] && this.openDetails.bind(this, months[i])}>
            {toAccounting(m)}
          </a>
        </td>
      })}
      {details && <AccountDetails accountName={name}
                                  accountId={accountId}
                                  start={moment(currentMonth).startOf('month').format("YYYY-MM-DD")}
                                  end={moment(currentMonth).endOf('month').format("YYYY-MM-DD")}
                                  toggle={this.openDetails.bind(this)}/>}
    </tr>
  }
}
export default MultiMonthAccount;