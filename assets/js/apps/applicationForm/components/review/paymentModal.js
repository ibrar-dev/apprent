import React from 'react';
import {Button, Modal, ModalHeader, ModalBody, Alert} from 'reactstrap';
import utils from '../utils';
import Payment from '../../models/payment'
import actions from '../../actions';
import Cards from 'react-credit-cards'
import moment from 'moment';

class PaymentModal extends React.Component {
  constructor(props) {
    super(props);

    const payment = new Payment();
    payment.set(
      'fees',
      [
        {
          name: 'application_fees',
          amount: props.appFee * props.numAdults,
          baseFee: props.appFee,
          numAdults: props.numAdults,
        },
        {
          name: 'admin_fees',
          amount: props.adminFee,
        },
      ]
    );
    this.state = {
      payment,
      displayConfirmation: false,
    };
    this.listenFocus();

    this.toggleConfirmation = this.toggleConfirmation.bind(this);
  }

  toggleConfirmation() {
    this.setState({displayConfirmation: !this.state.displayConfirmation})
  }

  editField(e) {
    const {payment} = this.state;
    payment.set(e.target.name, e.target.value);
    this.setState({...this.state, payment});
  }

  togglePayAdminFee() {
    const {payment} = this.state;
    const {adminFee} = this.props;
    const setAdminFee = payment.fees.find(f => f.name == 'admin_fees');
    setAdminFee.amount = setAdminFee.amount && setAdminFee.amount > 0 ? 0 : adminFee
    this.setState({...this.state, payment});
  }

  submit() {
    const {payment, credentials} = this.state;
    const onSuccess = this.props.onSubmit;
    if (payment.validate()) {
      this.setState({...this.state, submitting: true});

      // Tokenize against Authorize.net
      const {login_id, public_key, url} = this.props.cc_processor

      const cardNumber = payment.number.replace(/\s+/g, "")
      let [month, year] = payment.expiry.split("/")
      month = month.padStart(2, "0")

      const fullName = payment.name
      const cardCode = payment.cvc
      const zip = payment.zip
      const timestamp = moment.utc()
      const agreement_text = this.props.agreement_text

      const secureData = {
        authData: {
          clientKey: public_key,
          apiLoginID: login_id,
        },
        cardData: {
          cardNumber,
          month,
          year,
          cardCode,
          fullName,
          zip
        },
      }

      Accept.dispatchData(secureData, (response) => {
        // Accept.js tokenization fails
        if (response.messages.resultCode === "Error") {
          const {code, text} = response.messages.message[0]
          const errMsg = `${code}: ${text}`

          this.setState({...this.state, submitting: false, error: errMsg})
        } else {
          // We made a token! Now we submit payment
          payment.set("token_value", response.opaqueData.dataValue)
          payment.set("token_description", response.opaqueData.dataDescriptor)
          payment.set("agreement_accepted_at",timestamp)
          payment.set("agreement_text", agreement_text)

          actions.submitPayment(
            payment, credentials
          ).then(
            onSuccess
          ).catch(
            (error) => {
              this.setState(
                {
                  ...this.state,
                  submitting: false,
                  error: error.response.data.error
                }
              );
            }
          );
        }
      })

    }
    else {
      this.setState({...this.state, payment});
    }
  }

  dismissError() {
    this.setState({...this.state, error: null});
  }

  handleFocus(e) {
    this.setState({...this.state, focused: e.target.name});
  }

  listenFocus() {
    setTimeout(() => {
      const inputs = document.getElementsByClassName('payment-form')[0].getElementsByTagName('input');
      for (let i = 0; i < inputs.length; i++) {
        inputs[i].addEventListener('focus', this.handleFocus.bind(this));
      }
    }, 1000);
  }

  useAuthorize() {
    return this.props?.cc_processor?.processor === "Authorize"
  }

  // Add Authorize.net Accept.JS script if it doesn't already exist
  componentDidMount() {
    if(this.useAuthorize()) {
      const head = document.head
      const scripts = head.getElementsByTagName("script")
      const url = this.props?.cc_processor?.url

      const candidates = Array.from(scripts).filter(script => script.src === url)

      if (candidates.length == 0) {
        const script = document.createElement("script");
        script.src = url
        document.head.appendChild(script)
      }
    }
  }

  render() {
    const {payment, submitting, error, focused, displayConfirmation} = this.state;
    const {adminFee, cc_processor} = this.props;
    const setAdminFee = payment.fees.find(fee => fee.name == 'admin_fees');
    const setAppFee = payment.fees.find(fee => fee.name == 'application_fees');
    const totalFee = setAppFee.amount + (setAdminFee.amount || 0)
    const {close, lang} = this.props;
    const userField = utils.userField.bind(this, payment);
    const agreement_text = this.props.agreement_text

    return <Modal isOpen={true} size="lg">
      <ModalHeader toggle={close}>
        Payment Authorization
      </ModalHeader>
      <ModalBody>
        <Alert isOpen={!!error} color="danger" toggle={this.dismissError.bind(this)}>
          {error}
        </Alert>
        {
          displayConfirmation
            ? (
              <>
              <div
                className="overflow-auto"
                style={{maxHeight: "25em"}}
                dangerouslySetInnerHTML={{__html: agreement_text}}
              ></div>
              <div className="d-flex justify-content-around mt-5">
                <Button
                  className="py-2 px-4 text-white"
                  style={{fontSize: '1.5em'}}
                  color="danger"
                  onClick={() => this.toggleConfirmation()}
                  disabled={(!payment.validate() || submitting)}
                >
                  Cancel
                </Button>
                <Button
                  className="py-2 px-4 text-white"
                  style={{fontSize: '1.5em'}}
                  color="primary"
                  onClick={() => this.submit()}
                  disabled={(!payment.validate() || submitting)}
                >
                  {submitting ? 'Submitting...' : 'I Accept'}
                </Button>
              </div>
              </>
            )
            : (
              <>
              <div className="row margin-row">
                <div className="col-lg-5">
                  <span data-private>
                    <Cards
                      number={payment.number}
                      name={payment.name}
                      expiry={payment.expiry}
                      cvc={payment.cvc}
                      focused={focused}
                    />
                  </span>
                  <h3 className="text-left mt-2 ml-2">
                    Application Fee: &nbsp;&nbsp; ${setAppFee.amount}
                  </h3>
                  {
                    adminFee && adminFee > 0
                      ? (
                        <h3 className="text-left mt-2 ml-2">
                          Admin Fee: &nbsp;&nbsp; ${adminFee}
                        </h3>
                      )
                      : null
                  }
                </div>
                <div className="col-lg-7 payment-form">
                  {userField('name', 'Name')}
                  {userField('number', 'Card Number', 'ccNum', {dataPrivate: true})}
                  {userField('expiry', 'Expiration', 'expDate')}
                  {userField('cvc', 'CVV', 'number', {dataPrivate: true})}
                  {userField("zip", "ZIP Code", "number")}
                  {
                    adminFee && adminFee > 0
                      ? (
                        <div className="mt-3">
                          <label className="fancy-check d-inline-flex align-items-center">
                            <input
                              type="checkbox"
                              name="payAdminFee"
                              id="payAdminFee"
                              checked={setAdminFee.amount > 0}
                              onChange={() => this.togglePayAdminFee()}
                            />
                            <div className="checkbox"></div>
                            <div className="wipe"></div>
                            <div className="ml-2">{lang.pay_admin_fee_now}</div>
                          </label>
                          <p>{lang.fee_information}</p>
                          <p><b>{lang.fee_refundability}</b></p>
                        </div>
                      )
                      : null
                  }
                </div>
              </div>
              <div className="text-center">
                <Button
                  className="btn-block w-50 m-auto btn btn-info p-3 text-white"
                  style={{fontSize: '25px', fontWeight: 'bold'}}
                  color="info"
                  onClick={() => this.toggleConfirmation()}
                  disabled={(!payment.validate() || submitting)}
                >
                  {submitting ? 'Submitting...' : `Pay $${totalFee}`}
                </Button>
              </div>
              </>
            )
        }
      </ModalBody>
    </Modal>;
  }
}

export default PaymentModal;
