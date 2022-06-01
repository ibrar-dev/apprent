import React from 'react';
import {Alert, Button} from 'reactstrap';
import Cards from 'react-credit-cards';
import ReactDOM from 'react-dom';
import paymentField from './paymentField';
import validate from './validate';
import actions from "./actions";

class ApplicationPayment extends React.Component {
  constructor(props) {
    super(props);
    this.state = {errors: {}, payment: {name: '', number: '', expiry: '', cvc: '', amount: ADMIN_FEE}};
  }

  dismissError() {
    this.setState({...this.state, errors: {}});
  }

  handleFocus(e) {
    this.setState({...this.state, focused: e.target.name});
  }

  onSubmit() {
    this.setState({...this.state, submitting: false, success: true});
  }

  submit() {
    const {payment, credentials} = this.state;
    const onSuccess = this.onSubmit.bind(this);
    const errors = validate(payment);
    this.setState({...this.state, errors});
    if (Object.keys(errors).length === 0) {
      this.setState({...this.state, submitting: true});
      actions.submitPayment(payment, credentials).then(onSuccess).catch(error => {
        this.setState({...this.state, submitting: false, error});
      });
    }
  }

  change(e) {
    this.setState({...this.state, payment: {...this.state.payment, [e.target.name]: e.target.value}});
  }

  render() {
    const {payment, submitting, errors, focused, success} = this.state;
    if (success) {
      return <div>
        <h2 className="text-center">
          Your payment has been submitted successfully
        </h2>
        <h3 className="text-center">A confirmation email has been sent to your email.</h3>
        <h3 className="text-center">We look forward to having you at {PROPERTY_NAME}!</h3>
      </div>;
    }
    const error = this.state.error || Object.values(errors)[0];
    const change = this.change.bind(this);
    const focus = this.handleFocus.bind(this);
    return <div>
      <Alert isOpen={!!error} color="danger" toggle={this.dismissError.bind(this)}>
        {error}
      </Alert>
      <div className="row margin-row">
        <div className="col-lg-5">
          <Cards
            number={payment.number}
            name={payment.name}
            expiry={payment.expiry}
            cvc={payment.cvc}
            focused={focused}
          />
          <h3 className="text-center mt-2">
            Administration Fee: &nbsp;&nbsp; ${payment.amount}
          </h3>
        </div>
        <div className="col-lg-7 payment-form">
          {paymentField(payment.name, 'name', 'Name', change, focus, errors.name)}
          {paymentField(payment.number, 'number', 'Number', change, focus, errors.number)}
          {paymentField(payment.expiry, 'expiry', 'Expiration', change, focus, errors.expiry)}
          {paymentField(payment.cvc, 'cvc', 'CVV', change, focus, errors.cvc)}
        </div>
      </div>

      <div className="text-center">
        <Button className="btn-block w-50 m-auto btn btn-info p-3 text-white"
                style={{fontSize: '25px', fontWeight: 'bold'}}
                color="info"
                onClick={this.submit.bind(this)} disabled={submitting}>
          {submitting ? 'Submitting...' : `Pay $${payment.amount}`}
        </Button>
      </div>
    </div>;
  }
}

ReactDOM.render(<ApplicationPayment/>, document.getElementById('payment-container'));