import React, {Component} from "react";
import {toAccounting} from "../../../../utils";
import Account from './account';

class MultiMonthGroup extends Component {
  constructor(props) {
    super(props);
    this.state = {collapsed: props.collapsed, serial: props.serial}
  }

  accountsToDisplay() {
    const {group} = this.props;
    const {accounts} = group;
    return accounts
  }

  static getDerivedStateFromProps(props, state) {
    if (props.serial !== state.serial) {
      return {collapsed: props.collapsed, serial: props.serial}
    }
    return null;
  }

  toggleCollapse() {
    this.setState({collapsed: !this.state.collapsed})
  }

  render() {
    const {level, group, suppressZeros, numbers, months, serial} = this.props;
    const {name, groups, total} = group;
    const nextLevel = group.total_only ? level : level + 1;
    const {collapsed} = this.state;
    return <>
      {!group.total_only && <tr>
        <th colSpan={2} style={{paddingLeft: (level * 15) + 5}}>
          <span>{name}</span>
          <i onClick={this.toggleCollapse.bind(this)}
             className={`fas btn ${collapsed ? 'fa-chevron-right' : 'fa-chevron-down'} ml-1 icon-hover text-muted`}
             style={{fontSize: '0.7rem'}}/>
        </th>
        {total.map((m, i) => {
          return <th key={i} className="text-center border-top border-bottom"/>
        })}
      </tr>}
      {!collapsed && this.accountsToDisplay().map((account, i) => {
        return <Account key={i} months={months} account={account} level={nextLevel} numbers={numbers}/>
      })}
      {!collapsed && groups.length > 0 && groups.map((g, i) => {
        return <MultiMonthGroup collapsed={this.props.collapsed} serial={serial} index={i} key={i} group={g}
                                months={months} level={nextLevel} suppressZeros={suppressZeros}
                                numbers={numbers}/>
      })}
      <tr>
        <th colSpan={2} style={{paddingLeft: (level * 15) + 5}}>
          <span>Total {name}:</span>
        </th>
        {total.map((m, i) => {
          return <th key={i} className="text-center border-top border-bottom">{toAccounting(m)}</th>
        })}
      </tr>
    </>
  }
}

export default MultiMonthGroup;