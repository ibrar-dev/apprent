const luhnCheck = (value) => {
  if (/[^0-9-\s]+/.test(value) || value.length === 0) return 'Invalid card number';

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

  return (nCheck % 10) === 0 ? false : 'Invalid card number';
};

const validations = [
  {
    field: 'number',
    validation: luhnCheck
  },
  {
    field: 'name',
    validation: () => false
  },
  {
    field: 'expiry',
    validation: (expiry) => expiry.match(/\d\d\/\d\d/) ? false : 'Enter Expiration Date'
  },
  {
    field: 'cvc',
    validation: (cvc) => cvc.length === 3 || cvc.length === 4 ? false : 'Enter CVV'
  }
];

export default (payment) => {
  const errors = {};
  validations.forEach(v => {
      const error = v.validation(payment[v.field]);
      if (error) errors[v.field] = error;
    }
  );
  return errors;
}
