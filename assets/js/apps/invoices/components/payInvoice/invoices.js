import React from 'react';
import {withRouter} from 'react-router';
import {toCurr} from '../../../../utils';
import {Table, Button, Badge} from 'reactstrap';
import LineItems from './lineItems.js'

const sum = (list, field) => {
  return list.reduce((sum, item) => sum + (parseFloat(item[field]) || 0), 0);
};

function Invoice(props) {

  function payInfull(e, invoice) {
    e.stopPropagation();
    props.addCheck(invoice);
    props.change((state) => (invoice.invoicings.reduce((acc, x) => update(x.id, x.amount - sum(x.payments, "amount"), {...state, ...acc}), state)))
  }

  function update(invoicing_id, value, state) {
    const {payments} = state;
    return {payments: {...payments, [invoicing_id]: {amount: value, check_id: state.currentCheck}}};
  }

  function change(invoicing_id, value) {
    props.change((state) => update(invoicing_id, value, state))
  }

  const {payments, invoice, selectedInvoices, toggleInvoice} = props;
  return (<>
    <tr style={{
      borderWidth: '20px',
      cursor: 'pointer',
      backgroundColor: selectedInvoices.includes(invoice.id) ? '#f6f6f6' : null
    }}
        onClick={() => toggleInvoice(invoice)}>
      <td className="align-middle">{invoice.due_date}</td>
      <td className="align-middle">{invoice.number} - <Badge>{invoice.payee.name}</Badge></td>
      <td
        className="align-middle">{toCurr(invoice.amount - invoice.invoicings.reduce((total, inv) => total + (sum(inv.payments, 'amount') || 0), 0))}</td>
      <td className="nowrap">
        <Button size='sm' color='link' onClick={(e) => payInfull(e, invoice)}>Pay in full</Button>
      </td>
    </tr>
    {selectedInvoices.includes(invoice.id) && <tr
      style={{backgroundColor: '#e9e9e9'}}>
      <td/>
      <td colSpan={4} style={{padding: '0px'}}>
        <Table size="sm" style={{margin: 0}}>
          <thead>
          <tr style={{fontSize: 10}}>
            <td>Property</td>
            <td>Account</td>
            <td>Notes</td>
            <td>Open Balance</td>
            <td>Pay</td>
          </tr>
          </thead>
          <tbody>
          <LineItems payments={payments} addCheck={props.addCheck} selectCheck={props.selectCheck}
                     color={selectedInvoices.includes(invoice.id) ? '#e9e9e9' : null} invoice={invoice}
                     currentCheck={props.currentCheck} change={change}/>
          </tbody>
        </Table>
      </td>
    </tr>}
  </>)
}

export default withRouter(Invoice);
