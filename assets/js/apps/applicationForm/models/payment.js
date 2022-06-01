import Model from './model';

const luhnCheck = (value) => {
  if (/^[^0-9-\s]+$/.test(value) || value.length < 13 || value.length > 19 ) {
    return 'Invalid card number';
  }

  let nCheck = 0;
  let bEven = false;
  value = value.replace(/\D/g, "");

  for (let n = value.length - 1; n >= 0; n--) {
    const cDigit = value.charAt(n);
    let nDigit = parseInt(cDigit, 10);
    if (bEven) {
      if ((nDigit *= 2) > 9) nDigit -= 9;
    }
    nCheck += nDigit;
    bEven = !bEven;
  }

  return (nCheck % 10) === 0 ? true : 'Invalid card number';
};

class Payment extends Model {}

Payment.fields = [
  {
    field: 'fees',
    defaultValue: [],
    validation: () => true
  },
  {
    field: "token_value",
    defaultValue: "",
    validation: () => true
  },
  {
    field: "token_description",
    defaultValue: "",
    validation: () => true
  },
  {
    field: 'number',
    defaultValue: '',
    validation: luhnCheck
  },
  {
    field: "zip",
    defaultValue: "",
    validation: (zip) => zip.match(/^\d{5}$/) ? true : "Enter the five-digit ZIP code of your billing address"
  },
  {
    field: 'name',
    defaultValue: '',
    validation: () => true
  },
  {
    field: 'expiry',
    defaultValue: '',
    validation: (expiry) => expiry.match(/^\d{2}\/\d{2}$/) ? true : 'Enter Expiration Date'
  },
  {
    field: 'cvc',
    defaultValue: '',
    validation: (cvc) => cvc.match(/^\d{3,4}$/) ? true : 'Enter CVV'
  },
  {
    field: 'agreement_accepted_at',
    defaultValue: "",
    validation: () => true
  },
  {
    field: 'agreement_text',
    defaultValue: "",
    validation:() => true
  },
];

export default Payment;
