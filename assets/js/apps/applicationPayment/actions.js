import axios from 'axios';

const actions = {
  submitPayment(paymentObj) {
    const expDate = paymentObj.expiry.split('/');
    const formatted = `20${expDate[1]}-${expDate[0]}`;
    const payment = {
      number: paymentObj.number.replace(/\D/g, ""),
      cvv: paymentObj.cvc,
      exp: formatted,
      amount: paymentObj.amount,
      source: "admin-app-payment-form",
    };
    const applicationData = {
      application_id: APPLICATION_ID,
      admin_payment: payment,
      property_id: PROPERTY_ID
    };
    return axios.post('/api/rent_applications', applicationData);
  }
};

export default actions;
