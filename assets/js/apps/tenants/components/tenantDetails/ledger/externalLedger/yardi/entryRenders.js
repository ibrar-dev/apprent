import React from "react";
import {toCurr} from "../../../../../../../utils";

const yardiBaseURL = "https://www.yardiasp13.com/39876dasmen/pages/";
const yardiChargeURL = "GlCharge.aspx?Id=";
const yardiPaymentURL = "GlReceipt.aspx?Id=";

const urlType = {
  payment: yardiPaymentURL,
  charge: yardiChargeURL
}

function dateRender(entry) {
  return entry.date;
}

function descriptionRender(entry) {
  return entry.description;
}

function chargeRender(entry) {
  if (entry.type === "charge") return `$${entry.amount}`
  return ""
}

function paymentRender(entry) {
  if (entry.type === "payment") return `$${entry.amount}`
  return ""
}

function balanceRender(entry) {
  return toCurr(entry.balance);
}

function notesRender(entry) {
  return entry.notes;
}

function idRender(entry) {
  return <a 
    href={yardiBaseURL + urlType[entry.type] + entry.transaction_id}
    target="_blank"
  >
    {entry.transaction_id}
  </a>;
}

export {
  dateRender,
  descriptionRender,
  chargeRender,
  paymentRender,
  balanceRender,
  notesRender,
  idRender
} 