import React from 'react';
import moment from 'moment';
import AccountDetails from '../report/accountDetail';
import {toCurr} from "../../../../utils";

const condCurr = (value) => {
  if (value === 'N/A') return value;
  return toCurr(value, '');
};

class Account extends React.Component {
  state = {};

  openDetails(ytdMode) {
    this.setState({details: !this.state.details, ytdMode});
  }

  render() {
    const {level, account} = this.props;
    const indent = {paddingLeft: (level + 1) * 15};
    const {details, ytdMode} = this.state;
    return <tr className={account.num ? '' : 'font-weight-bold'}>
      <td>
        <div style={indent}>{account.num ? `${account.num} - ${account.name}` : `Total ${account.name}:`}</div>
      </td>
      <td className="text-right">
        <a onClick={this.openDetails.bind(this, false)}>{toCurr(account.ptd_actual, '')}</a>
      </td>
      <td className="text-right">
        <a onClick={this.openDetails.bind(this, false)}>{toCurr(account.ptd_budgeted, '')}</a>
      </td>
      <td className="text-right">
        <a onClick={this.openDetails.bind(this, false)}>{toCurr(account.ptd_variance, '')}</a>
      </td>
      <td className="text-right">
        <a onClick={this.openDetails.bind(this, false)}>{condCurr(account.ptd_percent_variance)}</a>
      </td>
      <td className="text-right">
        <a onClick={this.openDetails.bind(this, false)}>{toCurr(account.ytd_actual, '')}</a>
      </td>
      <td className="text-right">
        <a onClick={this.openDetails.bind(this, false)}>{toCurr(account.ytd_budgeted, '')}</a>
      </td>
      <td className="text-right">
        <a onClick={this.openDetails.bind(this, false)}>{toCurr(account.ytd_variance, '')}</a>
      </td>
      <td className="text-right">
        <a onClick={this.openDetails.bind(this, false)}>{condCurr(account.ytd_percent_variance)}</a>
      </td>
      <td/>
      {details && <AccountDetails start={ytdMode ? moment().startOf('year').format('YYYY-MM-DD') : undefined}
                                  end={ytdMode ? moment().format('YYYY-MM-DD') : undefined}
                                  accountName={account.name}
                                  accountId={account.account_id}
                                  toggle={this.openDetails.bind(this)}/>}
    </tr>;
  }
}

export default Account;