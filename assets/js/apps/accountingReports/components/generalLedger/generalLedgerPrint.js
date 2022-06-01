import React from 'react';
import {Table} from 'reactstrap';
import {toCurr} from '../../../../utils';

class LedgerItem extends React.Component {
  render() {
    const {item} = this.props;
    return <tr>
      <td/>
      <td>
        {item.date}
      </td>
      <td>
        {item.type}
      </td>
      <td>
        {item.description}
      </td>
      <td>
        {item.type === 'debit' && toCurr(item.amount)}
      </td>
      <td>
        {item.type === 'credit' && toCurr(item.amount)}
      </td>
      <td>
        {toCurr(item.running_total)}
      </td>
    </tr>
  }
}

class GeneralLedgerPrint extends React.Component {
  render() {
    const {data} = this.props;
    if (!data) return <div/>;
    const accounts = Object.keys(data);
    accounts.sort();
    return <Table className="data-table">
      {accounts.map(a => {
        return <React.Fragment key={a}>
          <thead>
          <tr>
            <th className="nowrap">{a}</th>
            <th colSpan={6}/>
          </tr>
          <tr>
            <th style={{width: '5%'}}/>
            <th>Date</th>
            <th>Type</th>
            <th>Description</th>
            <th>Debit</th>
            <th>Credit</th>
            <th>Balance</th>
          </tr>
          </thead>
          <tbody>
          {data[a].map((l, i) => <LedgerItem key={i} item={l}/>)}
          </tbody>
        </React.Fragment>
      })}
    </Table>;
  }
}

export default GeneralLedgerPrint;