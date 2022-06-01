import React from 'react';
import AccountDetailModal from "./accountDetailModal";
import {toCurr, sum} from '../../../utils';
import actions from "../actions";

class BudgetCell extends React.Component {
  state = {amount: this.props.amount || 0};

  changeAmount({target: {value}}) {
    const {changeValue} = this.props;
    changeValue(value);
    this.setState({amount: value});
  }

  render() {
    const {amount} = this.state;
    return <input style={{width: '6.5em'}} type="number" value={amount} onChange={this.changeAmount.bind(this)}/>;
  }
}

class BudgetLine extends React.Component {
  state = {};

  showDetails() {
    const {budgetLine, year, editMode} = this.props;
    if (editMode) return;
    actions.fetchDetailedAccount(year, budgetLine.id).then(r => {
      this.setState({details: r.data});
    });
  }

  closeDetails() {
    this.setState({details: null});
  }

  render() {
    const {budgetLine, changeValue, parent, editMode} = this.props;
    const {details} = this.state;
    return <>
      <tr onClick={this.showDetails.bind(this)}
          className={`cursor-pointer ${budgetLine.type === "total" ? 'bg-secondary text-white' : ''}`}>
        <td className={`nowrap align-middle ${editMode ? 'px-0' : ''}`}>{budgetLine.num} - {budgetLine.name}</td>
        <td className="align-middle">
          {budgetLine.type === 'category' ? '-' : toCurr(sum(budgetLine.budgets, 'amount'))}
        </td>
        {[...Array(12)].map((_, index) => {
          if (budgetLine.type === 'category') return <td key={index}>-</td>;
          const target = budgetLine.budgets.find(b => b.month_num === index + 1);
          const amount = (target || {amount: 0}).amount;
          const month = {...budgetLine, month: index + 1};
          return <td key={index} className={editMode ? 'px-0' : ''}>
            {editMode && budgetLine.type === 'account' ?
              <BudgetCell amount={amount} changeValue={changeValue.bind(parent, month)}/> : toCurr(amount)}
          </td>
        })}
      </tr>
      {details && <AccountDetailModal budgetLine={budgetLine} toggle={this.closeDetails.bind(this)} details={details}/>}
    </>;
  }
}

export default BudgetLine;