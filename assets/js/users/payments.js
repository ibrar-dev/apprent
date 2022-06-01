/* eslint-disable object-shorthand */
import axios from "axios";

$(document).ready(() => {
  const typeSelect = $("#paymentType");
  const amountInput = $("#paymentAmount");
  typeSelect.change(({target}) => {
    if ($(target).val() !== "custom") {
      amountInput.val("");
    }
  });

  calculateAndPlaceSurcharge();

  amountInput.focus(() => typeSelect.val("custom"));

  typeSelect.change(() => {
    calculateAndPlaceSurcharge();
  });

  amountInput.change(() => {
    calculateAndPlaceSurcharge();
  });

  amountInput.keyup(() => {
    calculateAndPlaceSurcharge();
  });

  amountInput.focus(() => {
    calculateAndPlaceSurcharge();
  });

  $("#paymentSource").change(() => {
    calculateAndPlaceSurcharge();
  });

  $("#oneTimePaymentIAgree").click(() => {
    $("#agreementTermsModal").modal("hide");
    submitOneTimePayment();
  });

  $("#oneTimePayment").submit((e) => {
    e.preventDefault();

    $("#agreementTermsModal").modal({backdrop: "static"});
  });

  function calculateAndPlaceSurcharge() {
    const select = $("#paymentSource");
    const paymentSourceId = select.val();
    const type = select.find(`option[value=${paymentSourceId}]`).data("type");

    const surchargeTextBase = "All payments made with credit or debit cards will have an additional 3% surcharge added to the amount to cover processing fees.";

    let amount = typeSelect.val();

    if (amount === "custom") {
      amount = parseFloat(amountInput.val()) || 0;
    }

    if (amount < 0) {
      amount = 0;
    }

    let formattedAmount = "";
    let surchargeText = surchargeTextBase;

    if (type === "cc") {
      const surchargeAmount = amount * 0.03;
      formattedAmount = formatAsCurrency(surchargeAmount);
      surchargeText = `${surchargeTextBase} Your surchage is ${formattedAmount}.`;
    } else {
      surchargeText = `${surchargeText}  There is no surcharge for payments made with a bank account.`;
    }

    $("#surchargeText").text(surchargeText);
  };

  function formatAsCurrency(amt) {
    const formatter = new Intl.NumberFormat("en-US", {
      style: "currency",
      currency: "USD",
      minimumFractionDigits: 2,
    });

    return formatter.format(amt);
  }

  function submitOneTimePayment() {
    // Block the page for a bit - we'll unblock as soon as payment submission
    // completes, successfully or otherwise
    const blocker = $("#spinner-overlay");
    blocker.toggle();

    const select = $("#paymentSource");
    const payment_source_id = select.val();
    const type = select.find(`option[value=${payment_source_id}]`).data("type");
    let amount = typeSelect.val();

    let agreement_text = $("#agreementTerms").html().trim();

    if (amount === "custom") {
      // If we can't parse, use 0 instead of NaN/undefined
      amount = parseFloat(amountInput.val()) || 0;
    }

    // we need a valid amount
    if (amount <= 0) {
      alert("Please enter a valid amount");
      blocker.toggle();
      return;
    }

    const amount_in_cents = Math.round(amount * 100);

    const args = {
      payment: {
        amount,
        amount_in_cents,
        payment_source_id,
        agreement_text,
      }
    };

    axios.post("/payments", args).then(() => {
      blocker.toggle();
      alert("Payment successful!");
      location.reload();
    }).catch((e) => {
      blocker.toggle();
      ModalMessage("Payment Error", e.response.data.error);
    });
  };

  $("#autopayForm").submit((e) => {
    e.preventDefault();
    submitAutopay();
  });

  $("#cancelAutopay").click((e) => {
    $("#autopayActive").prop("checked", false);
    submitAutopay();
  });

  function submitAutopay() {
    const paymentSource = $("#autopayPaymentSource");
    const active = $("#autopayActive")[0].checked;
    const paymentSourceId = paymentSource.val();
    const agreementText = $("#agreementTerms").html();

    let message = "Autopay disabled. Please remember to pay your balance.";

    if (active) {
      message = "Autopay updated";
    }

    const params = {
      agreement_text: agreementText,
      active: active,
      payment_source_id: paymentSourceId,
    };

    const blocker = $("#spinner-overlay");

    blocker.toggle();
    axios.patch("/profile", {autopay: params}).then(() => {
      alert(message);
      window.location.reload();
    }).catch(e => {
      blocker.toggle();
      ModalMessage("Payment Error", e.response.data.error);
    });
  };
});
