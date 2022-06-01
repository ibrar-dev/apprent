import React from 'react';
import {withRouter} from 'react-router';
import actions from '../actions';
import {toCurr} from '../../../utils';
import FancyCheck from '../../../components/fancyCheck';
import {Tooltip} from 'reactstrap';
import PayeeGroup from './payeeGroup'

const sum = (list, field) => {
  return list.reduce((sum, item) => sum + (parseFloat(item[field]) || 0), 0);
};

class Invoice extends React.Component {
  state = {toolTip: {}};

  deleteInvoice(e) {
    e.stopPropagation();
    if (confirm('Really delete this invoice?')) {
      actions.deleteInvoice(this.props.invoice);
    }
  }

  change({target: {name, value}}) {
    const invoice = {...this.props.invoice, [name]: value};
    this.props.change(invoice)
  }

  toggle() {
    this.setState({popoverOpen: !this.state.popoverOpen})
  }

  openToolTip(id) {
    const toolTip = this.state.toolTip;
    toolTip[id] ? delete toolTip[id] : toolTip[id] = true;
    this.setState({toolTip});
  }

  render() {
    const {invoice, history, invoiceIds, bankAccounts, toggleInvoice} = this.props;
    if (invoice.num_of_invoices) return <PayeeGroup invoice={invoice}/>;
    const {toolTip} = this.state;
    const propertyIds = [];
    const isUploading = (invoice.document_url || '').match(/images\/((loading)|(error))/);
    const checked = invoiceIds.includes(invoice.id);
    const paid = invoice.invoicings.reduce((total, inv) => total + (sum(inv.payments, 'amount') || 0), 0);
    const unpaid = Math.round((parseFloat(invoice.amount) - paid) * 100);
    return <tr className="link-row" onClick={() => history.push(`/invoices/${invoice.id}`, {})}>
      <td className="align-middle">
        {bankAccounts.length === 0 &&
        <div>
          <i id={`invoice${invoice.id}`} className="fas fa-exclamation text-warning"
             style={{fontSize: 18, marginLeft: 8}}> </i>
          <Tooltip target={`invoice${invoice.id}`} placement={"right"} isOpen={toolTip[invoice.id]}
                   toggle={this.openToolTip.bind(this, invoice.id)}>
            No Bank Account
          </Tooltip>
        </div>}
        {bankAccounts.length > 0 && unpaid > 0 && <div className="d-flex">
          <FancyCheck inline checked={checked} name='check' onChange={() => toggleInvoice(invoice)}/>
        </div>
        }
      </td>
      <td className="align-middle">{invoice.date}</td>
      <td className="align-middle">{invoice.due_date}</td>
      <td className="align-middle">{invoice.number}</td>
      <td className="align-middle">{invoice.payee.name}</td>
      <td className="align-middle">{invoice.invoicings.map(i => {
        if (propertyIds.includes(i.property_id)) return null;
        propertyIds.push(i.property_id);
        return <div key={i.property_id}>{i.property_name}</div>
      })}</td>
      <td
        className="align-middle">{invoice.invoicings[0].bank_accounts[0] && invoice.invoicings[0].bank_accounts[0].bank_name}</td>
      <td className="align-middle">{toCurr(invoice.amount)}</td>
      <td className="align-middle">
        {toCurr(paid)}
      </td>
      <td className="align-middle min-width p-0 position-relative">
        {isUploading && <img style={{width: 25}} src={invoice.document_url}/>}
        {invoice.document_url && !isUploading &&
        <a href={`/invoices/${invoice.id}/doc`}
           className="position-absolute d-flex align-items-center justify-content-center"
           style={{top: 0, left: 0, bottom: 0, right: 0}}
           onClick={(e) => e.stopPropagation()} target="_blank">
          <i className="fas fa-file"/>
        </a>}
      </td>
      <td className="align-middle">
        <a onClick={this.deleteInvoice.bind(this)}>
          <i className="fas fa-times text-danger"/>
        </a>
      </td>
    </tr>
  }
}

export default withRouter(Invoice);
