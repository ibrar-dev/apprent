import React from 'react';
import Account from './account';
import {toCurr} from '../../../../utils';

class Group extends React.Component {
  constructor(props) {
    super(props);
    this.state = {collapsed: props.collapsed, serial: props.serial}
  }

  static getDerivedStateFromProps(props, state) {
    if (props.serial !== state.serial) {
      return {collapsed: props.collapsed, serial: props.serial}
    }
    return null;
  }

  accountsToDisplay() {
    const {group: {accounts}, suppressZeros} = this.props;
    if (accounts.length > 0) {
      const balanceCol = accounts[0].length === 4 ? 2 : 4;
      return suppressZeros ? accounts.filter((a) => parseInt(a[balanceCol]) !== 0) : accounts;
    }
    return accounts;
  }

  toggleCollapse() {
    this.setState({collapsed: !this.state.collapsed})
  }

  render() {
    const {level, group, suppressZeros, balance} = this.props;
    const {collapsed} = this.state;
    const {name, groups, total, year_total, total_only, accounts} = group;
    const indent = {paddingLeft: level * 15};
    if (suppressZeros && !total_only && total === 0 && year_total === 0) return <tr/>;
    if (suppressZeros && total_only && accounts[0].total === 0 && accounts[0].ytd === 0) return <tr/>;
    return <>
      {!total_only && <tr>
        <td>
          <div style={indent}>
            <b>{name}</b>
            <i onClick={this.toggleCollapse.bind(this)} style={{fontSize: '0.7rem'}}
               className={`fas btn fa-chevron-${collapsed ? 'right' : 'down'} ml-1 icon-hover text-muted py-0`}/>
          </div>
        </td>
        <td/>
        {!balance && <td/>}
      </tr>}
      {!collapsed && this.accountsToDisplay().map((account, i) => <Account key={i} account={account}
                                                                           level={total_only ? level - 1 : level}/>)}
      {!collapsed && groups.length > 0 && groups.map((g, i) => <Group key={i} collapsed={this.props.collapsed} group={g}
                                                                      level={total_only ? level : level + 1}
                                                                      balance={balance}
                                                                      suppressZeros={suppressZeros}/>)}
      {!total_only && <tr>
        <td>
          <div style={indent}><b>Total {name}:</b></div>
        </td>
        <td className="text-right">
          <b>{toCurr(total, '')}</b>
        </td>
        {!balance && <td className="text-right">
          <b>{toCurr(year_total, '')}</b>
        </td>}
      </tr>}
    </>
  }
}

export default Group;
