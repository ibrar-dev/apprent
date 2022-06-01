import React from 'react';
import {Table, Button, Tooltip} from 'reactstrap';
import Invoicing from './invoicing';
import {toCurr} from '../../../utils';
import NewPayment from './newPayment';

const sum = (list, field) => {
  return list.reduce((sum, item) => sum + (parseFloat(item[field]) || 0), 0);
};

class Invoicings extends React.Component {
  state = {};

  add() {
    const {invoicings, onChange} = this.props;
    const id = invoicings.reduce((max, i) => i.id > max ? i.id : max, 0) + 1;
    const newInvoicings = invoicings.concat([{amount_paid: 0, id, payments: []}]);
    onChange({target: {name: 'invoicings', value: newInvoicings}});
  }

  newPayment() {
    this.setState({...this.state, newPayment: !this.state.newPayment});
  }

  remove(index) {
    const {invoicings, onChange} = this.props;
    invoicings.splice(index, 1);
    onChange({target: {name: 'invoicings', value: invoicings}});
  }

  change(index, {target: {name, value}}) {
    const {invoicings, onChange} = this.props;
    let new_value = value;
    const newInvoicings = invoicings.map((inv, i) => i === index ? {...inv, [name]: new_value} : inv);
    onChange({target: {name: 'invoicings', value: newInvoicings}});
  }

  numBelowSum() {
    const {invoice, amount} = this.props;
    const inputted = sum(invoice.invoicings, 'amount');
    if (parseFloat(amount).toFixed(2) === inputted.toFixed(2)) {
      return <span className="text-success">{toCurr(amount)} <i id="info_tooltip" className="fas fa-info-circle ml-1" /></span>
    } else {
      return <span className="text-danger">{toCurr(amount - inputted)} <i id="info_tooltip" className="fas fa-info-circle ml-1" /></span>
    }
  }

  toggleTooltip() {
    this.setState({...this.state, tooltip: !this.state.tooltip})
  }

  render() {
    const {invoicings, validationContext, invoice} = this.props;
    const {newPayment, tooltip} = this.state;
    const invoicing = {amount: invoice.amount};
    return <Table>
      <thead>
      <tr>
        <th className="align-middle min-width">
          <a onClick={this.add.bind(this)}>
            <i className="fas fa-plus-circle fa-2x text-success"/>
          </a>
        </th>
        <th className="align-middle" style={{width: '17em'}}>Property</th>
        <th className="align-middle" style={{width: '25em'}}>Account</th>
        <th className="align-middle">Note</th>
        <th className="align-middle" style={{width: 120}}>Amount</th>
        {<th className="d-flex align-items-center align-middle align-center justify-content-between">{!invoice.isNew && 'Payments'}<Button onClick={this.newPayment.bind(this)} style={{float:"right"}}className="btn-info">Pay All
        </Button></th>}
      </tr>
      </thead>
      <tbody>
      {invoicings.map((inv, i) => <Invoicing key={inv.id} inv={inv} validationContext={validationContext}
                                             invoice={invoice}
                                             index={i}
                                             change={this.change.bind(this, i)}
                                             remove={this.remove.bind(this, i)}/>)}
      <tr>
        <td/>
        <td colSpan={3}>
          <b>Total</b>
        </td>
        <td className="d-flex flex-column">
          <span>{toCurr(sum(invoicings, 'amount'))}</span>
          <span>{this.numBelowSum()}</span>
        </td>
        <td>{!invoice.isNew ? toCurr(invoicings.reduce((total, inv) => total + (sum(inv.payments, 'amount') || 0), 0)): 0.00}</td>
      </tr>
      </tbody>
      <Tooltip placement="left" isOpen={tooltip} target="info_tooltip" toggle={this.toggleTooltip.bind(this)}>
        Green Text means the lines equal the amount on the invoice. Red Text will show how much still needs to be added until the numbers match up.
      </Tooltip>
      {newPayment && <NewPayment invoicing={invoicing} invoice={invoice} batch={true} toggle={this.newPayment.bind(this)}/>}
    </Table>
  }
}

export default Invoicings;
