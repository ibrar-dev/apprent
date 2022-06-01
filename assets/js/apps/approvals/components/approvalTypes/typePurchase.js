import React, {Component} from "react";
import {Input, Table} from "reactstrap";
import {connect} from "react-redux";
import {toCurr} from "../../../../utils";
import Select from '../../../../components/select';
import MoneySpentModal from '../moneySpentModal';

class TypePurchase extends Component {
  constructor(props){
    super(props);
    this.state = {approval: props.approval};
    if (props.approval.costs.length < 1) {
      props.approval.costs.push({category_id: null, amount: null});
      // props.approval.params.amount = null;
    }
  }

  stateReturn(){
    return this.state.approval
  }

  getPayee() {
    const {approval: {params}, payees} = this.props;
    if (!params || !params.payee_id) return "";
    let p = payees.filter(p => p.id === params.payee_id)[0];
    if (p) return p.name;
    return "N/A"
  }

  changeParams({target: {name, value}}) {
    const {approval: {params}, approval} = this.props;
    params[name] = value;
    const newApproval = {...approval, params: params};
    this.setState({...this.state, approval: newApproval})
  }

  changeCosts(index, {target: {name, value}}) {
    const approval = {...this.state.approval};
    approval.costs[index][name] = value;
    if (name === "amount") {
      this.changeParams({target: {name: "amount", value: this.totalAmounts()}});
    } else {
      this.setState({...this.state, approval: approval})
    }
  }

  totalAmounts() {
    const {approval} = this.state;
    return approval.costs.reduce((acc, c) => {
      if (!c.amount) return acc;
      return acc + parseFloat(c.amount)
    }, 0);
  }

  addCostObject() {
    const {approval} = this.state;
    let last = approval.costs.slice(-1)[0];
    if (!last.amount) return;
    approval.costs.push({category_id: null, amount: null});
    this.setState({...this.state, approval: approval})
  }

  deleteCostObject(i) {
    const {approval} = this.state;
    approval.costs.splice(i, 1);
    this.setState({...this.state, approval: approval})
  }

  percentageCalculator(part, whole) {
    return (part / whole)*100
  }

  toggleMoneySpentModal(category) {
    this.setState({...this.state, moneySpentModal: category})
  }

  render() {
    const {approval: {params, costs, property_id}, editPage, accountingCategories} = this.props;
    const {moneySpentModal} = this.state;
    editPage && this.addCostObject();
    return <React.Fragment>
      {moneySpentModal && <MoneySpentModal property_id={property_id} category={moneySpentModal} toggle={this.toggleMoneySpentModal.bind(this, null)} />}
      <div className="labeled-box mt-3">
        <Input value={this.getPayee()} disabled/>
        <div className="labeled-box-label">Vendor</div>
      </div>
      <div className="labeled-box mt-3">
        <Input value={costs && costs.length && costs[0].category_id && costs[0].amount ? toCurr(params.amount) : `Please use the categories below to update the amount. ${params.amount ? `(${toCurr(params.amount)})` : ""}`} disabled={true} name="amount" onChange={this.changeParams.bind(this)} />
        <div className="labeled-box-label">Amount</div>
      </div>
      <div className="labeled-box mt-3">
        <Input type="textarea" value={params.description || ""} disabled={!editPage} name="description" onChange={this.changeParams.bind(this)} />
        <div className="labeled-box-label">Description</div>
      </div>
      {!editPage && costs.length > 0 && <Table>
        <thead>
        <tr>
          <th>Category</th>
          <th>Amount</th>
          <th>MTD <small>(This Request)</small></th>
        </tr>
        </thead>
        <tbody>
          {costs.map(c => {
            const cat = accountingCategories.filter(a => c.category_id === a.id)[0];
            return <tr key={c.id}>
              <td>{c.name}</td>
              <td>{toCurr(c.amount)}</td>
              {cat && cat.spent && <td onClick={cat.spent > 0 ? this.toggleMoneySpentModal.bind(this, cat.id) : null} className="cursor-pointer"><b>{toCurr(cat.spent)}</b>/<small>{this.percentageCalculator(c.amount, parseFloat(cat.spent)).toFixed(2)}%</small></td>}
            </tr>
          })}
        </tbody>
      </Table>}
      {editPage && <Table borderless>
        <thead>
        <tr>
          <th>Category</th>
          <th>Amount</th>
        </tr>
        </thead>
        <tbody>
        {costs.map((c, i) => {
          const cat = accountingCategories.filter(a => c.category_id === a.id)[0];
          return <React.Fragment key={i}>
            <tr>
              <td className="w-75">
                <Select name="category_id"
                        value={c.category_id}
                        onChange={this.changeCosts.bind(this, i)}
                        options={accountingCategories.map(p => {
                          return {label: p.name, value: p.id}
                        })} />
              </td>
              <td>
                <Input type="number" name="amount" value={parseFloat(c.amount)} onChange={this.changeCosts.bind(this, i)}/>
              </td>
              <td className="text-warning">
                {i !== 0 && c.amount && <i className="fas fa-trash" onClick={this.deleteCostObject.bind(this, i)} />}
              </td>
            </tr>
            {cat && cat.spent && <tr className="mt-0">
              <td>Spent This Month So Far /<small>This requests percentage</small></td>
              <td colSpan={2}><b>{toCurr(cat.spent)}</b>/<small>{this.percentageCalculator(c.amount, parseFloat(cat.spent)).toFixed(2)}%</small></td>
            </tr>}
          </React.Fragment>
          //<td   colSpan={2}><b>{toCurr(cat.spent)}</b>/<small>{toCurr(parseFloat(cat.spent) + parseFloat(c.amount) || 0)}</small></td>
        })}
        </tbody>
      </Table>}
    </React.Fragment>
  }
}

export default TypePurchase;
