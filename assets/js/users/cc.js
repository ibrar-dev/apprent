import axios from 'axios';

const patterns = {
  amex: /^3[47]/,
  discover: /^65[4-9]|64[4-9]|6011|(622(?:12[6-9]|1[3-9][0-9]|[2-8][0-9][0-9]|9[01][0-9]|92[0-5]))/,
  maestro: /^(5018|5020|5038|6304|6759|6761|6763)/,
  mastercard: /^5[1-5]/,
  visa: /^4/,
  jcb: /^(?:2131|1800|35\d{3})/,
  dinersclub: /^3(?:0[0-5]|[68][0-9])/,
  unionpay: /^62/,
  laser: /^(6304|6706|6709|6771)/,
  'visa invisible': /.?/
};

const CreditCard = {
  luhnCheck(value) {
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
    return (nCheck % 10) === 0 ? null : 'Invalid card number';
  },

  validateDate(date) {
    if (!/^\d{2}\/\d{2}$/.test(date)) {
      return 'Invalid Expiration Date';
    }

    const [month, year] = date.split("/")
    const parsedMonth = parseInt(month);
    const parsedYear = parseInt(year);

    // Validate month -- we do it this way to handle NaN
    if (parsedMonth === NaN || parsedMonth < 1 || parsedMonth > 12) {
      return 'Invalid Expiration Date';
    }

    // For Date() object -
    // Month is 0 - Jan, 1 - Feb, .... 11 - Dec
    // Year is represented as 2019 ... year % 1000 -> 19 (last 2 digits)
    const now = new Date();
    const yearInPast = parsedYear < now.getFullYear() % 100
    const monthInPast = parsedMonth < now.getMonth() + 1 && parsedYear <= now.getFullYear() % 100
    if (yearInPast || monthInPast) {
      return 'Invalid Expiration Date';
    }
    return null;
  },

  validate() {
    // Build a credit card prototype -- start with blank values, then pull from
    // form and populate.
    const cc = {number: '', cvc: '', exp: '', card_name: '', card_zip};
    Object.keys(cc).forEach(field => cc[field] = $('#' + field).val());
    cc.number = cc.number.replace(/\s/g, '');

    // Detect card type
    Object.keys(patterns).some(t => {
      return patterns[t].test(cc.number) ? (cc.brand = t) && true : false
    });

    const validations = {
      card_name: cc.card_name.length > 3 ? null : 'Please enter a name',
      number: CreditCard.luhnCheck(cc.number),
      cvc: /^\d{3,4}$/.test(cc.cvc) ? null : 'Invalid CVC',
      exp: CreditCard.validateDate(cc.exp),
      card_zip: cc.card_zip.length > 4 ? null : "Please enter the billing ZIP code"
    };

    const errors = Object.keys(validations).map(field => {
      const target = $(`#${field}`);
      const error = validations[field];
      error ? target.addClass('is-invalid') : target.removeClass('is-invalid');
      target.parent().find('.invalid-feedback').text(error);
      return error;
    });

    return [!errors.some(s => s), cc];
  },

  setCardType({target: {value}}) {
    let cardType;
    Object.keys(patterns).some(t => patterns[t].test(value) ? (cardType = t) && true : false);
    $('#cc-icon').attr('class', `card-logo ${cardType}`);
  },

  blockForm() {
    $('#add-cc-card').find('.spinner-overlay').toggle();
  },

  // In the event of a tokenization failure, we show an error message
  addErrorMessage(msg) {
    const el = document.getElementById("tokenize-feedback");
    if (!el) {
      return
    }

    //Set the new message
    el.innerText = msg
    el.className = "alert alert-danger"
  },

  submit() {
    const [valid, cc] = CreditCard.validate();
    if (valid) {
      // Attach Authorize.net tokenization
      const {login_id, public_key} = ccTokenizationCredentials

      const cardNumber = cc.number.replace(/\s+/g, "")
      let [month, year] = cc.exp.split("/")
      month = month.padStart(2, "0")
      const zip = cc.card_zip
      const cardCode = cc.cvc
      const fullName = cc.card_name

      const last_4 = cardNumber.substring(cardNumber.length - 4)

      const secureData = {
        authData: {
          clientKey: public_key,
          apiLoginID: login_id
        },
        cardData: {
          cardNumber,
          cardCode,
          fullName,
          month,
          year,
          zip
        }
      }

      CreditCard.blockForm();

      Accept.dispatchData(secureData, (response) => {
        if (response.messages.resultCode === "Error") {
          const {code, text} = response.messages.message[0]
          const errMsg = `Error: ${text} (${code})`
          CreditCard.addErrorMessage(errMsg)

          CreditCard.blockForm();
        } else {
          const token_value = response.opaqueData.dataValue;
          const token_description = response.opaqueData.dataDescriptor
          const data = {
            token_value,
            token_description,
            last_4,
            type: "cc",
            brand: cc.brand,
            card_name: cc.card_name,
            exp: cc.exp
          }

          axios.post('/payment_sources', {cc: data}).then(
            () => location.reload()
          ).catch(
            (error) => {
              CreditCard.blockForm();
            }
          )
        }
      })
    }
  }
};

export default CreditCard;
