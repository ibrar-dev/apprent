import React from 'react';
import TabbedBox from '../../../../components/tabbedBox';
import Pagination from '../../../../components/pagination';
import {toCurr} from '../../../../utils';
import moment from "moment";

const currentMonth = moment();
currentMonth.startOf('month');

const headers = [
  {label: 'Date'},
  {label: 'Type'},
  {label: 'Description'},
  {label: 'Reference'},
  {label: 'Debit'},
  {label: 'Credit'},
  {label: 'Balance'}
];

class LedgerItem extends React.Component {
  render() {
    const {item, selectedAccount} = this.props;
    return <tr>
      <td>
        {item.date}
      </td>
      <td>
        {item.type}
      </td>
      <td>
        {item.desc}
      </td>
      <td>
        <a target="_blank" href={`/${item.url}`}>
          View
        </a>
      </td>
      <td>
        {item.type === 'debit' && toCurr(item.amount)}
      </td>
      <td>
        {item.type === 'credit' && toCurr(item.amount)}
      </td>
      {selectedAccount !== "All" && <td>
        {toCurr(item.running_total)}
      </td>}
      {item.account && selectedAccount === "All" && <td>{item.account.split("-")[0]}</td>}
    </tr>
  }
}

class GeneralLedger extends React.Component {
  state = {accountIndex: 0, startDate: currentMonth, endDate: currentMonth};

  setAccount(accountLink) {
    const {data, parent} = this.props;
    if (accountLink.id === 0) {
      parent.setGlAccount(-1);
    } else {
      const accountId = Object.keys(data).find(k => {
        const [accountName, id] = k.split('-');
        return accountName === accountLink.label;
      }).split('-')[1];
      parent.setGlAccount(accountId);
    }
    this.setState({accountIndex: accountLink.id});
  }

  render() {
    const {data} = this.props;
    const {accountIndex} = this.state;
    if (!data) return <div/>;
    const accounts = ['All'].concat(Object.keys(data).map(key => key).sort());
    const accountLinks = accounts.map((account, index) => {
      return {label: account.split("-")[0], id: index, icon: false};
    });
    const selectedAccount = accounts[accountIndex];
    const accountItems = data[selectedAccount] || Object.entries(data).map(entry => entry[1].map(a => ({
      ...a,
      account: entry[0]
    }))).flat().sort((a, b) => moment(a.date).diff(moment(b.date)));
    return <div>
      <TabbedBox links={accountLinks} active={accountIndex} header="" onNavigate={this.setAccount.bind(this)}>
        <Pagination collection={accountItems}
                    tableClasses="table-sm"
                    toggleIndex={true}
                    component={LedgerItem}
                    additionalProps={{selectedAccount}}
                    headers={selectedAccount !== 'All' ? headers : headers.slice(0, headers.length - 1).concat({label: 'Account'})}
                    field="item"
                    title={selectedAccount.split("-")[0]}/>
      </TabbedBox>
    </div>;
  }
}

export default GeneralLedger;
