import React, {Component} from 'react';
import {Table} from 'reactstrap';
import moment from 'moment';
import Group from './group'

class MultiMonth extends Component {
  state = {collapsed: false, serial: 0};

  extractMonths() {
    const {dates: {start_d, end_d}} = this.props;
    let numberOfMonths = end_d.diff(start_d, 'months');
    let months = new Array(numberOfMonths + 1).fill().map((_, i) => moment(start_d).add(i, 'months'));
    return {months, number: numberOfMonths}
  }

  render() {
    const {result, suppressZeros, collapsed, serial} = this.props;
    const {months, number} = this.extractMonths();
    return <Table size="sm" bordered>
      <thead>
      <tr className="table-active">
        <th colSpan='2'>Account</th>
        {months.map(m => <th className="text-center nowrap" key={m}>{moment(m).format("MMM YYYY")}</th>)}
        <th className="text-center">Total</th>
      </tr>
      </thead>
      <tbody>
      {result.map((g, i) => <Group collapsed={collapsed} serial={serial} index={i} months={months} group={g}
                                   key={i} level={0} suppressZeros={suppressZeros} numbers={number}/>)}
      </tbody>
    </Table>
  }
}

export default MultiMonth
