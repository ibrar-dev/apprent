import React from 'react';
import {connect} from 'react-redux';
import {Modal, ModalHeader, ModalBody, ModalFooter, Row, Col, Button, Input} from 'reactstrap';
import moment from 'moment';
import Select from '../../../components/select';
import DatePicker from '../../../components/datePicker';
import Checkbox from '../../../components/fancyCheck';
import {toCurr, numToLang} from '../../../utils';
import actions from '../actions';

const prepad = (number) => {
  const initial = `00000${number}`;
  return initial.substring(initial.length - 6);
};

class NewPayment extends React.Component {
  constructor(props) {
    super(props);
    const {invoice, bankAccounts} = props;
    this.state = {
      check: {date: moment(), payee_id: invoice.payee_id, bank_account_id: ((bankAccounts[0] || {id: null}).id)},
      checkMode: true,
      amount: this.props.batch ? this.props.invoice.invoicings.reduce((acc, b) => {
        return acc + (b.amount - b.payments.reduce((acc2, b2) => {
          return acc2 + b2.amount
        }, 0))
      }, 0) : (this.props.invoicing.amount - this.props.invoicing.payments.reduce((acc2, b2) => {
        return acc2 + b2.amount
      }, 0)),
      paymentDate: moment()
    };
  }

  change({target: {name, value}}) {
    this.setState({check: {...this.state.check, [name]: value}});
  }

  changeAmount({target: {value}}) {
    const {invoicing, batch, invoice} = this.props;
    const realAmount = batch ? invoice.invoicings.reduce((acc, b) => {
      return acc + (b.amount - b.payments.reduce((acc2, b2) => {
        return acc2 + b2.amount
      }, 0))
    }, 0) : (invoicing.amount - invoicing.payments.reduce((acc2, b2) => {
      return acc2 + b2.amount
    }, 0));
    value = value < 0 ? 0 : value;
    value = value > realAmount ? realAmount : value;
    this.setState({amount: value});
  }

  changePaymentDate({target: {value}}) {
    this.setState({paymentDate: value});
  }

  changePaymentAccount({target: {value}}) {
    this.setState({account_id: value});
  }

  changeMode() {
    this.setState({checkMode: !this.state.checkMode});
  }

  save() {
    const {check, checkMode, amount, paymentDate, account_id} = this.state;
    const {invoicing, batch, invoice, toggle} = this.props;
    const newAmount = invoice.invoicings.reduce((acc, b) => {
      return acc + (b.amount - b.payments.reduce((acc2, b2) => {
        return acc2 + b2.amount
      }, 0))
    }, 0);
    invoice.invoicings.forEach(x => x.amount = (x.amount - x.payments.reduce((acc2, b2) => {
      return acc2 + b2.amount
    }, 0)));
    const postMonth = moment().startOf('month').add(10, 'hours');
    const params = batch ? {
      amount: newAmount,
      inserted_at: paymentDate,
      post_month: postMonth,
      invoice,
      account_id
    } : {account_id, amount, inserted_at: paymentDate, invoicing_id: invoicing.id, post_month: postMonth};
    if (checkMode) params.check = {...check, amount};
    batch ? actions.createPayments(params).then(toggle) : actions.createPayment(params).then(toggle);
  }

  render() {
    const {toggle, invoice, bankAccounts: ba, payees, accounts} = this.props;
    const {check, checkMode, paymentDate, amount, account_id} = this.state;
    const bankAccounts = ba.filter(b => b.account_id === account_id);
    const account = bankAccounts.filter(a => a.id === check.bank_account_id)[0] || bankAccounts[0] || {};
    const number = (account.max_number || 0) + 1;
    const change = this.change.bind(this);
    return <Modal isOpen={true} toggle={toggle} size="lg">
      <ModalHeader toggle={toggle}>
        New Payment
      </ModalHeader>
      <ModalBody>
        <Row>
          <Col className="d-flex align-items-center">
            <Checkbox label="Create Check" checked={checkMode} onChange={this.changeMode.bind(this)}/>
          </Col>
          <Col>
            <div className="labeled-box">
              <Input name="amount" onChange={this.changeAmount.bind(this)} value={amount}/>
              <div className="labeled-box-label">Payment Amount</div>
            </div>
          </Col>
          <Col>
            <div className="labeled-box">
              <Select name="account_id" onChange={this.changePaymentAccount.bind(this)} value={account_id}
                      options={accounts.filter(a => a.is_cash).map(a => {
                        return {label: a.name, value: a.id};
                      })}/>
              <div className="labeled-box-label">Payment Account</div>
            </div>
          </Col>
          <Col>
            <div className="labeled-box">
              <DatePicker name="paymentDate" value={paymentDate} onChange={this.changePaymentDate.bind(this)}/>
              <div className="labeled-box-label">Payment Date</div>
            </div>
          </Col>
        </Row>
        {checkMode && !account_id && bankAccounts.length === 0 &&
        <div className="mt-3">Please enter a payment account.</div>}
        {checkMode && account_id && bankAccounts.length === 0 &&
        <div className="mt-3">There are no bank accounts for the selected payment account.
          Please enter one in the <a href="/bank_accounts">Bank Accounts</a> section.</div>}
        {checkMode && bankAccounts.length > 0 && <div className="border p-3 mt-3" style={{background: 'whitesmoke'}}>
          <Row className="mb-4">
            <Col style={{lineHeight: '1.2em'}}>
              <h4 className="m-0">{account.name}</h4>
              <div>{account.address.street}</div>
              <div>{account.address.city} {account.address.state} {account.address.zip}</div>
            </Col>
            <Col className="text-center">
              {bankAccounts.length > 1 && <Select name="bank_account_id" value={check.bank_account_id} onChange={change}
                                                  options={bankAccounts.map(a => {
                                                    return {label: a.name, value: a.id}
                                                  })}/>}
              {bankAccounts.length === 1 && bankAccounts[0].bank_name}
            </Col>
            <Col className="text-center">
              <div>{number}</div>
              <DatePicker name="date" value={check.date} onChange={change}/>
            </Col>
          </Row>
          <Row className="mb-2">
            <Col sm={3}>TO THE ORDER OF</Col>
            <Col style={{fontFamily: 'Courier'}}>{payees.find(x => x.id === invoice.payee_id).name}</Col>
            <Col sm={2} style={{fontFamily: 'Courier'}}>{toCurr(amount)}</Col>
          </Row>
          <Row className="mb-3">
            <Col sm={3}/>
            <Col style={{fontFamily: 'Courier'}}>{numToLang(amount).toUpperCase()} DOLLARS</Col>
          </Row>
          <Row className="mb-2">
            <Col sm={6}>MEMO &nbsp;&nbsp;&nbsp;{invoice.notes}</Col>
            <Col/>
          </Row>
          <Row>
            <Col className="text-center">
              <div style={{fontFamily: 'MICREncoding', fontSize: 25}}>
                c{prepad(number)}ca{account.routing_number}a{account.account_number}c
              </div>
            </Col>
          </Row>
        </div>}
      </ModalBody>
      <ModalFooter>
        <Button onClick={this.save.bind(this)} color="info">
          Create
        </Button>
      </ModalFooter>
    </Modal>
  }
}

export default connect(({bankAccounts, invoices, payees, accounts}) => {
  return {bankAccounts, invoices, payees, accounts};
})(NewPayment);