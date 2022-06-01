import React from 'react';
import {connect} from 'react-redux';
import {Button} from 'reactstrap';
import Invoice from './invoice';
import PayInvoices from './payInvoices';
import PayInvoice from './payInvoice';
import Pagination from '../../../components/pagination';
import Filters from './filters';

const sum = (list, field) => {
  return list.reduce((sum, item) => sum + (parseFloat(item[field]) || 0), 0);
};

class Invoices extends React.Component {
  state = {
    additionalFilters: {},
    invoiceIds: [],
    invoices: []
  };

  filters(i) {
    const {additionalFilters} = this.state;
    if (additionalFilters.openInvoices && i.amount - i.invoicings.reduce((total, inv) => total + (sum(inv.payments, 'amount') || 0), 0).toFixed(2) <= 0) return false;
    if (additionalFilters.account_id && i.payable_account_id !== additionalFilters.account_id) return false;
    if (additionalFilters.post_month && i.post_month !== additionalFilters.post_month) return false;
    if (additionalFilters.notes && (!i.notes || !i.notes.toLowerCase().includes(additionalFilters.notes.toLowerCase()))) return false;
    return !(additionalFilters.bank_id && !i.invoicings.map(i => i.bank_accounts.map(b => b.id)).flat().includes(additionalFilters.bank_id));
  }

  filtered() {
    const {invoices, payees} = this.props;
    const groups = invoices.reduce((acc, invoice) => {
      if (!this.filters(invoice)) return acc;
      acc[invoice.payee_id] = [invoice].concat(acc[invoice.payee_id] || []);
      return acc
    }, {});
    return Object.entries(groups).map((g) => [{
      name: payees.find(p => p.id === parseInt(g[0]))?.name,
      num_of_invoices: g[1].length
    }, ...g[1]]).flat();
  }

  changeFilter({target: {name, value}}) {
    if (value) {
      this.setState({additionalFilters: {...this.state.additionalFilters, [name]: value}});
    } else {
      const filters = {...this.state.additionalFilters};
      delete filters[name];
      this.setState({additionalFilters: filters});
    }
  }

  toggleInvoice(invoice) {
    const {invoiceIds} = this.state;
    const index = invoiceIds.findIndex(x => x === invoice.id);
    if (index >= 0) {
      invoiceIds.splice(index, 1);
      this.setState({invoiceIds})
    } else {
      this.setState({invoiceIds: [...invoiceIds, invoice.id]})
    }
  }

  change({target: {name, value}}) {
    this.setState({[name]: value})
  }

  togglePayModal() {
    this.setState({payModal: !this.state.payModal});
  }

  togglePayMode(bankId) {
    this.setState({payMode: !this.state.payMode, payModal: false, bankId});
  }

  render() {
    const {history, bankAccounts, invoices} = this.props;
    const {invoiceIds, additionalFilters, action, bankId, payModal, payMode} = this.state;
    const headers = [
      {label: '', min: true},
      {label: 'Date', sort: 'date'},
      {label: 'Due Date', sort: 'due_date'},
      {label: 'Number', sort: 'number'},
      {label: 'Payee'},
      {label: 'To'},
      {label: 'Bank'},
      {label: 'Total'},
      {label: 'Paid'},
      {label: '', min: true},
      {label: '', min: true}
    ];
    if (payMode) {
      return <PayInvoice bankId={bankId} toggle={this.togglePayMode.bind(this)}
                         invoices={invoices.filter(invoice => invoiceIds.includes(invoice.id))}/>;
    }
    return <div>
      <Pagination collection={this.filtered()}
                  component={Invoice}
                  headers={headers}
                  field="invoice"
                  filters={<Filters additionalFilters={additionalFilters} change={this.changeFilter.bind(this)}/>}
                  additionalProps={{
                    toggleInvoice: this.toggleInvoice.bind(this),
                    action,
                    bankAccounts,
                    invoiceIds
                  }}
                  toggleIndex={true}
                  title={<div className="d-flex">
                    <Button className="my-0"
                            color="success"
                            size="sm"
                            onClick={() => history.push('/invoices/new', {})}>
                      <i className="fas fa-plus-circle"/> New Invoice
                    </Button>
                    <Button className="my-0 ml-3" onClick={this.togglePayModal.bind(this)}
                            disabled={invoiceIds.length === 0}
                            color='success'>Pay {invoiceIds.length ? invoiceIds.length : ''} Invoices</Button>
                  </div>}
      />
      {payModal && <PayInvoices bankAccounts={bankAccounts} additionalFilters={additionalFilters}
                                togglePayMode={this.togglePayMode.bind(this)}
                                toggle={this.togglePayModal.bind(this)}/>}
    </div>
  }
}

export default connect(({bankAccounts, invoices, payees}) => {
  return {bankAccounts, invoices, payees};
})(Invoices);
