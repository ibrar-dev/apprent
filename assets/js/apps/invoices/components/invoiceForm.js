import React from 'react';
import {connect} from 'react-redux';
import {Card, CardHeader, CardBody, CardFooter, Button, Input, Row, Col, Label} from 'reactstrap';
import moment from 'moment';
import NewPayee from './newPayee';
import Invoicings from './invoicings';
import NewAccount from './newAccount';
import ScanAttachment from './scanAttachment';
import actions from '../actions';
import {DatePicker} from "antd";
// import DatePicker from '../../../components/datePicker';
import Uploader from '../../../components/uploader';
import clearUpload from '../../../components/uploader/clearUpload';
import {toCurr} from "../../../utils";
import {ValidatedSelect, ValidatedInput, validate} from '../../../components/validationFields';

const dateFormats = ['MM/DD/YY', 'MM/DD/YYYY', 'MM-DD-YY', 'MM-DD-YYYY'];

class InvoiceForm extends React.Component {
  constructor(props) {
    super(props);
    this.state = this.initialState();
  }

  setPostMonthStorage({target: {value}}) {
    if (value === 'off') {
      this.setState({defaultPostMonth: this.state.post_month})
    } else if (value === 'on') {
      this.setState({defaultPostMonth: ''})
    }
  }

  initialState() {
    const payableAccount = window.localStorage.getItem('payableAccount');
    const paymentAccount = window.localStorage.getItem('paymentAccount');
    return {
      ...this.props.invoice,
      post_month: this.props.invoice.post_month || localStorage.defaultPostMonth || moment().date(1).format('YYYY-MM-DD'),
      due_date: this.props.invoice.due_date,
      amount: this.props.invoice.amount,
      payable_account_id: this.props.invoice.payable_account_id || parseInt(payableAccount),
      paymentAccount: paymentAccount,
      payableAccount: payableAccount,
      defaultPostMonth: localStorage.defaultPostMonth
    };
  }

  componentDidUpdate(prevProps, prevState) {
    const {defaultPostMonth} = this.state;
    if (prevState.defaultPostMonth !== defaultPostMonth) {
      defaultPostMonth ? localStorage.setItem("defaultPostMonth", defaultPostMonth) :
        localStorage.removeItem("defaultPostMonth")
    }
  }

  static getDerivedStateFromProps(props, state) {
    return {
      ...state, invoicings: state.invoicings.map((inv) => {
        const invoicing = props.invoice.invoicings.find(i => i.id === inv.id) || inv;
        return {...inv, payments: invoicing.payments}
      })
    }
  }

  saveAccount(field, value) {
    if (!this.state[field]) {
      window.localStorage.setItem(field, value);
      this.setState({...this.state, [field]: value})
    } else if (this.state[field] !== value) {
      window.localStorage.removeItem(field);
      window.localStorage.setItem(field, value);
      this.setState({...this.state, [field]: value})
    } else {
      window.localStorage.removeItem(field);
      this.setState({...this.state, [field]: null})
    }
  }


  purchaseOrderToInvoice(purchaseOrder) {
    this.setState({
      number: purchaseOrder.number,
      payee_id: purchaseOrder.vendor_id,
      purchase_order_id: purchaseOrder.id,
      purchase_order_number: purchaseOrder.number,
      amount: purchaseOrder.total,
      invoicings: purchaseOrder.line_items.map(li => ({
        amount: li.price,
        account_id: li.account_id,
        property_id: purchaseOrder.property_id,
        payments: []
      }))
    })
  }

  changeDate(name, value) {
    this.setState({...this.state, [name]: value}, () => this.updateDueDate(name));
  }

  change({target: {name, value}}) {
    if (value.newAccount) return this.setState({newAccount: value.newAccount});
    if (name === 'post_month') return this.setState({[name]: value, defaultPostMonth: ''});
    this.setState({...this.state, [name]: value.format ? value.format('YYYY-MM-DD') : value}, () => this.updateDueDate(name));
  }

  updateDueDate(name) {
    if (!["payee_id", "date"].includes(name)) return;
    const {payee_id, date, id} = this.state;
    if (id) return;
    const {payees} = this.props;
    const payee = payees.filter(p => p.id === payee_id)[0];
    if (!payee || !date) return;
    this.setState({...this.state, due_date: moment(date).add(payee.due_period, 'days')});
  }

  changeAttachment(document) {
    this.setState({document});
  }

  closeNewAccount() {
    this.setState({newAccount: null});
  }

  save() {
    let filteredInvoicings = [...this.state.invoicings].filter(invoicing => {
      let copy = {...invoicing};
      delete copy.id;
      delete copy.payments;
      return !(Object.values(copy).every(value => !value));
    });
    const {due_date, date} = this.state;
    if (!due_date || !date) return this.setState({...this.state, datesError: true})
    this.setState({invoicings: filteredInvoicings, datesError: false},
      () => {
        validate(this).then(() => {
            const func = this.state.id ? 'updateInvoice' : 'createInvoice';
            const {document, ...params} = this.state;
            document.upload().then(() => {
              if (document.uuid) params.document = {uuid: document.uuid};
              const promise = actions[func](params);
              if (!this.state.id) promise.then(this.resetState.bind(this));
            });
        }).catch(e => {
          console.log("error", e)
        });
      })
  }

  resetState() {
    this.key += 1;
    const payableAccount = window.localStorage.getItem('payableAccount');
    const paymentAccount = window.localStorage.getItem('paymentAccount');
    const defaultPostMonth = localStorage.getItem("defaultPostMonth");
    this.setState({
      number: null,
      notes: null,
      payable_account_id: parseInt(payableAccount),
      date: null,
      cash_account: null,
      payee_id: null,
      due_date: null,
      post_month: defaultPostMonth,
      amount: 0,
      invoicings: [{id: 1, payments: [], validate: true}],
      document: null,
      paymentAccount: paymentAccount,
      payableAccount: payableAccount,
    });
    clearUpload.resolve();
  }

  key = 0;

  toggleScanner() {
    this.setState({scanner: !this.state.scanner});
  }

  postMonths() {
    let months = [];
    let limit = 6;
    Array.apply(null, Array(limit)).forEach((_a, i) => {
      const value = moment().subtract(limit - i, 'months').date(1);
      months.push({label: value.format('MMMM YYYY'), value: value.format('YYYY-MM-DD')})
    });
    Array.apply(null, Array(limit + 1)).forEach((_a, i) => {
      const value = moment().add(i, 'months').date(1);
      months.push({label: value.format('MMMM YYYY'), value: value.format('YYYY-MM-DD')})
    });
    return months;
  }

  render() {
    const {accounts, payees, history} = this.props;
    const {payableAccount, datesError} = this.state;
    const invoice = this.state;
    const change = this.change.bind(this);
    return <div className="d-flex" key={this.key}>
      <Col>
        <Card>
          <CardHeader>
            <Row className='d-flex'>
              {invoice.id ? 'Edit' : 'New'} Invoice
              {invoice.purchase_order_id && <Col md={3} className='ml-auto d-flex'>
                <Card>
                  <a href={`http://administration.appcount.test:4002/purchases/${invoice.purchase_order_id}`}
                     style={{color: 'red'}}><i
                    className="fas fa-link"/> {`Purchase Order #${invoice.purchase_order_number}`}
                  </a>
                </Card>
              </Col>}
            </Row>
          </CardHeader>
          <CardBody>
            {invoice.newAccount &&
            <NewAccount accountType={invoice.newAccount} toggle={this.closeNewAccount.bind(this)}/>}
            <Row className="mb-3">
              <Col sm={2} className="d-flex align-items-center">From</Col>
              <Col sm={7}>
                <ValidatedSelect context={this} autoFocus tabIndex={1}
                                 validation={(d) => !!d} feedback="Select Payee"
                                 name="payee_id" value={invoice.payee_id || ''} onChange={change}
                                 options={payees.map(p => {
                                   return {label: p.name, value: p.id}
                                 })}/>
              </Col>
              <Col sm={3}>
                <NewPayee/>
              </Col>
            </Row>
            <Row>
              <Col>
                <div className="labeled-box">
                  <ValidatedInput context={this} tabIndex={2}
                                  validation={(d) => !!d} feedback="Enter Number"
                                  onChange={change} name="number" value={invoice.number || ''}/>
                  <div className="labeled-box-label">Number</div>
                </div>
              </Col>
              <Col>
                <div className="labeled-box">
                  <DatePicker format={dateFormats} allowClear
                              tabIndex={3} name="date"
                              className={"w-100"}
                              value={invoice.date ? moment(invoice.date) : null}
                              style={{borderColor: datesError && !invoice.date ? 'red' : ''}}
                              onChange={this.changeDate.bind(this, "date")} />
                  {datesError && !invoice.date && <small className={"text-danger"}>Invoice Date is Required</small>}
                  <div className="labeled-box-label">Invoice Date</div>
                </div>
              </Col>
            </Row>
            <Row>
              <Col>
                <div className="labeled-box mt-4">
                  <ValidatedInput context={this} tabIndex={4}
                                  validation={(d) => {
                                    const total = toCurr(invoice.invoicings.reduce((total, inv) => total + parseFloat(inv.amount), 0));
                                    return !!d && total === toCurr(invoice.amount)}
                                  }
                                  feedback={invoice.amount ? "Total and Invoicings Dont Match" : "Enter Total"}
                                  onChange={change} name="amount" value={invoice.amount || ''}/>
                  <div className="labeled-box-label">Total</div>
                </div>
              </Col>
              <Col>
                <div className="labeled-box mt-4">
                  <DatePicker format={dateFormats} allowClear
                              tabIndex={5} name="due_date"
                              className={"w-100"} value={invoice.due_date ? moment(invoice.due_date) : null}
                              style={{borderColor: datesError && !invoice.date ? 'red' : ''}}
                              onChange={this.changeDate.bind(this, "due_date")}/>
                  {datesError && !invoice.date && <small className={"text-danger"}>Invoice Date is Required</small>}
                  <div className="labeled-box-label">Due Date</div>
                </div>
              </Col>
            </Row>
            <Row>
              <Col>
                <div className="labeled-box mt-4">
                  <ValidatedSelect context={this}
                                   tabIndex={6}
                                   validation={(d) => !!d}
                                   feedback="Select Account"
                                   onChange={change} value={invoice.payable_account_id}
                                   name="payable_account_id"
                                   options={accounts.filter(a => a.is_payable).map(a => {
                                     return {label: a.name, value: a.id};
                                   }).concat([{
                                     label: 'NEW ACCOUNT',
                                     value: {newAccount: 'is_payable'}
                                   }])}/>
                  <div className="labeled-box-label">Payable Account</div>
                </div>
                {!invoice.id && <Label check className='ml-4'>
                  <Input type='checkbox' checked={payableAccount === invoice.payable_account_id}
                         value={payableAccount === invoice.payable_account_id ? 'on' : 'off'}
                         onChange={this.saveAccount.bind(this, "payableAccount", invoice.payable_account_id)}/>
                  <small>Remember</small>
                </Label>}
              </Col>
              <Col>
                <div className="labeled-box mt-4">
                  <ValidatedSelect context={this}
                                   validation={(d) => !!d}
                                   feedback="Select post month"
                                   onChange={change}
                                   value={invoice.post_month}
                                   name="post_month"
                                   tabIndex={7}
                                   options={this.postMonths()}/>
                  <div className="labeled-box-label">Post Month</div>
                  {!invoice.id && <Label check className='ml-4'>
                    <Input type='checkbox' checked={!!this.state.defaultPostMonth}
                           value={this.state.defaultPostMonth ? 'on' : 'off'}
                           onChange={this.setPostMonthStorage.bind(this)}/>
                    <small>Remember</small>
                  </Label>}
                </div>
              </Col>
            </Row>
            <Row>
              <Col className="d-flex align-items-center">
                <Row className="mt-2 flex-auto">
                  <Col sm={4} className="d-flex align-items-center">Attachment</Col>
                  <Col sm={8}>
                    <div className="d-flex justify-content-between align-items-center">
                      <Uploader clearUpload={clearUpload} url={invoice.document_url || null}
                                onChange={this.changeAttachment.bind(this)}/>
                      {invoice.id && invoice.document_url &&
                      <a href={`/invoices/${invoice.id}/doc`} target="_blank"
                         className="btn btn-outline-success ml-2">View</a>}
                      {/*<Button className="nowrap" color="info" outline onClick={this.toggleScanner.bind(this)}>*/}
                      {/*  Scan Attachment*/}
                      {/*</Button>*/}
                    </div>
                    {invoice.scanner && <ScanAttachment toggle={this.toggleScanner.bind(this)}/>}
                  </Col>
                </Row>
              </Col>
              <Col>
                <div className="labeled-box mt-4">
                  <Input type="textarea" name="notes" rows={3} value={invoice.notes || ''}
                         tabIndex={9}
                         onChange={change}/>
                  <div className="labeled-box-label">Notes</div>
                </div>
              </Col>
            </Row>
            <Row className="mt-2">
              <Col>
                <Invoicings onChange={change} amount={invoice.amount} invoice={invoice}
                            validationContext={this}
                            invoicings={invoice.invoicings || []}/>
              </Col>
            </Row>
          </CardBody>
          <CardFooter className="d-flex justify-content-between">
            <Button color="danger" className="w-25 btn-block" onClick={() => history.push('/invoices', {})}>
              Cancel
            </Button>
            <Button color="success" className="m-0 w-25 btn-block" onClick={this.save.bind(this)}>
              Save
            </Button>
          </CardFooter>
        </Card>
      </Col>
    </div>;
  }
}

export default connect(({accounts, properties, payees, purchaseOrders}) => {
  return {accounts, properties, payees, purchaseOrders};
})(InvoiceForm);
