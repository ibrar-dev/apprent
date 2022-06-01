import React from 'react';
import moment from 'moment';
import {connect} from 'react-redux';
import {Input, Button} from 'reactstrap';
import {toCurr} from '../../../../utils';

const sum = (list, field) => {
  return list.reduce((sum, item) => sum + (parseFloat(item[field]) || 0), 0);
};

class LineItems extends React.Component {

  newPayment() {
    this.setState({...this.state, newPayment: !this.state.newPayment});
  }

  update(line, value, state) {
    const line_items = this.props.invoice.invoicings.map(li => {
      if (li.id == line.id) {
        return {...li, to_pay: value, checkId: state.currentCheck}
      } else {
        return li
      }
    });
    return {...this.props.invoice, invoicings: line_items};
  }

  change(line, {target: {name, value}}){
    this.props.addCheck(this.props.invoice)
    const {invoice} = this.props;
    // invoicings.splice(invoicings.findIndex(i => i.id == line.id), 1, {...line, [name]: value})
    // this.props.change(invoicings)
    this.props.change(line.id, value)
  }

  selectCheck(inv) {
    if (inv.checkId) {
      this.props.selectCheck({number: inv.checkId})
    }
    else {
      this.props.addCheck(this.props.invoice)
    }
  }

  render() {
    const {properties, accounts, remove, validationContext, invoice, index, currentCheck, payments} = this.props;
    return invoice.invoicings.map(inv => (<tr key={inv.id} style={{backgroundColor: payments[inv.id] && payments[inv.id].check_id == currentCheck.number ? '#e6ffec' : null}}>
      <td style={{padding: 5, fontSize: 12}}>
        {properties.find(p => p.id == inv.property_id).name}
      </td>
      <td style={{padding: 5, fontSize: 12}}>
        {accounts.find(a => a.id == inv.account_id).name}
      </td>
      <td style={{padding: 5, fontSize: 12}}>
        {inv.notes || ''}
      </td>
      <td style={{padding: 5, fontSize: 12}}>
        {(inv.amount - sum(inv.payments, "amount")).toFixed(2) || 0.00}
      </td>
      <td style={{padding: 5, fontSize: 12}}>
        <input size='sm'
               value={payments[inv.id] && payments[inv.id].amount || ''} type='number' onChange={this.change.bind(this, inv)}/>
      </td>
      <td>{inv.checkId && `Check #: ${inv.checkId}`}</td>
    </tr>))
  }
}

export default connect(({properties, accounts, invoices}) => {
  return {properties, accounts, invoices};
})(LineItems);
