import React from 'react';
import moment from 'moment';
import AccountDetails from './accountDetail';
import {toCurr} from "../../../../utils";

class Account extends React.Component {
  state = {};

  openDetails(ytdMode) {
    this.setState({details: !this.state.details, ytdMode});
  }

  render() {
    const {level, account} = this.props;
    const indent = {paddingLeft: (level + 1) * 15};
    if (account.name) {
      return <tr>
        <td>
          <div style={indent}><b>Total {account.name}:</b></div>
        </td>
        <td className="text-right">
          <b>{toCurr(account.total, '')}</b>
        </td>
        {account.ytd !== undefined && <td className="text-right">
          <b>{toCurr(account.ytd, '')}</b>
        </td>}
      </tr>
    }
    const [accountNum, accountName, amount, accountId, ytd] = account;
    const {details, ytdMode} = this.state;
    return <tr>
      <td>
        <div style={indent}>{accountNum} - {accountName}</div>
      </td>
      <td className="text-right">
        <a onClick={this.openDetails.bind(this, false)}>{toCurr(amount, '')}</a>
      </td>
      {ytd !== undefined && <td className="text-right">
        <a onClick={this.openDetails.bind(this, true)}>{toCurr(ytd, '')}</a>
      </td>}
      {details && <AccountDetails start={ytdMode ? moment().startOf('year').format('YYYY-MM-DD') : undefined}
                                  end={ytdMode ? moment().format('YYYY-MM-DD') : undefined}
                                  accountName={accountName}
                                  accountId={accountId}
                                  toggle={this.openDetails.bind(this)}/>}
    </tr>;
  }
}

export default Account;