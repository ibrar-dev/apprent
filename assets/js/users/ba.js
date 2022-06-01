import axios from "axios";

const BankAccount = {
  validateRouting(number) {
    try {
      parseInt(number, 10);
    } catch (err) {
      return "ACH routing number is not Valid";
    }

    if (number.length !== 9 || number.charAt(0) === "5") {
      return "ACH routing number is not Valid";
    }

    // First two digits are between 01-12, 21-32, 61-72, 80
    const validStart = number.substring(0, 2);
    const regexp = /0(?=[1-9])|1(?=[0-2])|2(?=[0-9])|3(?=[0-2])|6(?=[0-9])|7(?=[0-2])|80/;
    if (!validStart.match(regexp)) {
      return "ACH routing number is not Valid";
    }

    // ABA Routing Number Checksum
    let n = 0;
    for (let i = 0; i < number.length; i += 3) {
      n += parseInt(number.charAt(i), 10) * 3
        + parseInt(number.charAt(i + 1), 10) * 7
        + parseInt(number.charAt(i + 2), 10);
    }
    if (n === 0 || n % 10 !== 0) {
      return "ACH routing number is not Valid";
    }
    return null;
  },

  validate() {
    const ba = {
      account_number: "",
      routing_number: "",
      account_name: "",
      subtype: "",
    };

    Object.keys(ba).forEach(field => ba[field] = $('#' + field).val());

    const validations = {
      account_name: ba.account_name.length > 3 ? null : "Please enter a name",
      routing_number: BankAccount.validateRouting(ba.routing_number),
      account_number: /^\d{3,17}$/.test(ba.account_number) ? null : "Please enter a valid account number",
    };

    const errors = Object.keys(validations).map(field => {
      const target = $(`#${field}`);
      const error = validations[field];
      error ? target.addClass("is-invalid") : target.removeClass("is-invalid");
      target.parent().find(".invalid-feedback").text(error);
      return error;
    });

    return [!errors.some(s => s), ba];
  },

  blockForm() {
    $("#add-ba").find(".spinner-overlay").toggle();
  },

  submit() {
    const [valid, ba] = BankAccount.validate();
    if (valid) {
      BankAccount.blockForm();
      axios.post("/payment_sources", {ba}).then(() => {
        location.reload();
      });
    }
  },
};

export default BankAccount;
