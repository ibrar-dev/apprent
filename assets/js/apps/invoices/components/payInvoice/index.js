import React from 'react';
import {connect} from 'react-redux';
import {Row, Col, Button, Container} from 'reactstrap';
import moment from 'moment';
import {numToLang} from '../../../../utils';
import printPdf from '../../../../utils/pdfPrinter';
import actions from '../../actions';
import setLoading from "../../../../components/loading";
import Pagination from "../../../../components/pagination";
import Invoice from './invoices.js'
import Checks from './checks.js'
import {withRouter} from "react-router-dom";

const sum = (list, field) => {
  return list.reduce((sum, item) => sum + (parseFloat(item[field]) || 0), 0);
};

class NewPayment extends React.Component {
  constructor(props) {
    super(props);
    const {bankAccounts, bankId} = props;
    this.checkNo = bankAccounts.find(b => b.id === bankId).max_number + 1;
    this.state = {
      checks: [],
      invoices: props.invoices,
      currentCheck: null,
      selectedInvoices: [],
      payments: {}
    };
  }

  change(func) {
    // setState supports a callback
    this.setState(func)
  }

  removeCheck(e, check) {
    e.stopPropagation();
    let checks = [...this.state.checks];
    let {payments} = this.state;
    const index = checks.findIndex(x => x.number === check.number);
    checks.splice(index, 1);
    Object.keys(payments).map(p => {
      if (payments[p].check_id === check.number) {
        delete payments[p]
      }
    });
    this.setState({checks: checks, currentCheck: checks[0].number, payments: payments})
  }

  selectCheck(check = {}) {
    const {checks} = this.state;
    const {invoices} = this.props;
    const selectedCheck = checks.find(c => c.number === check.number);
    const selectedInvoices = invoices.filter(i => i.payee_id === selectedCheck.payee_id).map(i => i.id);
    this.setState({currentCheck: check.number, selectedInvoices})
  }

  toggleInvoice(invoice) {
    const {selectedInvoices} = this.state;
    if (selectedInvoices.includes(invoice.id)) {
      selectedInvoices.splice(selectedInvoices.indexOf(invoice.id), 1);
      this.setState({selectedInvoice: [...selectedInvoices]})
    } else {
      this.setState({selectedInvoices: selectedInvoices.concat([invoice.id])});
    }
  }

  addCheck(invoice = {}) {
    const {checks, currentCheck} = this.state;
    const check = checks.find(c => c.payee_id === invoice.payee_id);
    if (check && invoice.payee_id) {
      const checkIndex = checks.findIndex(c => c.number === currentCheck);
      const selectedCheck = checks[checkIndex];
      if (selectedCheck.payee_id && selectedCheck.payee_id !== invoice.payee_id) {
        return this.setState({currentCheck: check.number});
      } else {
        checks.splice(checkIndex, 1, {...selectedCheck, payee_id: invoice.payee_id});
        return this.setState({checks});
      }
    }
    const newCheck = {
      date: moment(),
      number: this.checkNo++,
      payee_id: invoice.payee_id || ''
    };
    checks.push(newCheck);
    this.setState({checks, currentCheck: newCheck.number})
  }

  autoGenerate() {
    const {payees} = this.props;
    let checks = [];
    const payments = {};
    this.state.invoices.forEach(i => {
      const checkIndex = checks.findIndex(c => c.payee_id === i.payee_id);
      const payee = payees.find(p => p.id === i.payee_id);
      let currentCheck;
      if (payee.consolidate_checks && checkIndex >= 0) {
        currentCheck = checks[checkIndex]
      } else {
        checks.push({date: moment(), number: this.checkNo++, payee_id: i.payee_id});
        currentCheck = checks[checks.length - 1]
      }
      i.invoicings.forEach(inv => {
        const amount = inv.amount - sum(inv.payments, "amount");
        payments[inv.id] = {amount, invoicing_id: inv.id, check_id: currentCheck.number}
      })
    });
    this.setState({checks, payments, currentCheck: this.checkNo - 1})
  }

  save() {
    let {checks, payments} = this.state;
    const {bankId} = this.props;
    setLoading(true);
    checks = checks.map(c => {
      const invoicings = Object.entries(payments).map((e) => {
        const key = e[0];
        const value = e[1];
        return value.invoicing_id ? value : Object.assign(value, {invoicing_id: key});
      }).filter(p => p.check_id === c.number);
      return {
        ...c,
        amount: sum(invoicings, "amount"),
        amount_lang: numToLang(sum(invoicings, "amount")),
        invoicings: invoicings.map(p => ({invoicing_id: p.invoicing_id, amount: p.amount})),
        bank_account_id: bankId
      }
    }).filter(c => sum(c.invoicings, "amount") > 0);
    actions.createBatchPayments({checks}).then(r => {
      printPdf(r.data.checks)
    }).finally(() => {
      setLoading(false);
    })
  }

  render() {
    const {bankAccounts, payees, toggle} = this.props;
    const {checks, invoices, currentCheck, payments, selectedInvoices} = this.state;
    const headers = [{label: "DUE DATE"}, {label: "INVOICE"}, {label: "OPEN BALANCE"}, {label: '', min: true}];
    return <Container fluid>
      <Row className="mt-4">
        <Col sm={9} className="pr-5">
          <Pagination component={Invoice}
                      collection={invoices}
                      additionalProps={{
                        toggleInvoice: this.toggleInvoice.bind(this),
                        addCheck: this.addCheck.bind(this),
                        selectCheck: this.selectCheck.bind(this),
                        change: this.change.bind(this),
                        currentCheck: checks.find(c => c.number === currentCheck),
                        payments,
                        checks,
                        selectedInvoices,
                        bankAccounts,
                      }}
                      title={<div className="d-flex align-items-center">
                        <div>Invoices</div>
                        <Button className="ml-3" color="danger" outline onClick={toggle}>Cancel</Button>
                        <Button className="ml-3" color="success" outline onClick={this.save.bind(this)}>
                          Generate Checks
                        </Button>
                      </div>}
                      headers={headers}
                      field="invoice"
          />
        </Col>
        <Col sm={3} className='pl-5'>
          <Row className='d-flex lead justify-content-center'>
            <Col md='1'>
              <i style={{cursor: "pointer"}}
                 onClick={this.addCheck.bind(this)}
                 className="fas fa-plus text-success"/>
            </Col>
            <Col>
              <p>Checks</p>
            </Col>
            <div className="pr-3">
              <Button size='sm' onClick={this.autoGenerate.bind(this)} color='success' outline>Auto Generate</Button>
            </div>
          </Row>
          <Row>
            <Col>
              <Checks bankAccounts={bankAccounts} payees={payees} checks={checks} invoices={invoices}
                      payments={payments} currentCheck={checks.find(c => c.number === currentCheck)}
                      change={this.change.bind(this)}
                      selectCheck={this.selectCheck.bind(this)} removeCheck={this.removeCheck.bind(this)}/>
            </Col>
          </Row>
        </Col>
      </Row>
    </Container>
  }
}

export default withRouter(connect(({bankAccounts, payees}) => {
  return {bankAccounts, payees};
})(NewPayment));
