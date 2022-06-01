import React from 'react';
import moment from 'moment';

function submittedOnRender(order) {
  if (order.type === "Vendor") {
    return <span>{moment(order.creation_date).format("MM/DD/YY")}</span>
  }
  return <span>{moment(order.inserted_at).utc().local().format("MM/DD/YY h:mmA")}</span>
}

const cancelledOnString = ({type, cancellation, updated_at}) => {
  if (type === "Vendor") {
    return moment(updated_at).utc().local().format("MM/DD/YY h:mmA")
  }
  if (cancellation && cancellation["time"]) {
    return moment(cancellation["time"]).utc().local().format("MM/DD/YY h:mmA")
  }
  return "";
}

const cancelledOnRender = (order) => (<span>{cancelledOnString(order)}</span>);

const unitRender = (order) => {
  return <span>{unitString(order)}</span>
};
const unitString = (order) => (order?.unit?.number || "")
const unitSorter = (order) => {
  return {
    sorter: (a, b) => unitString(a).localeCompare(unitString(b)),
    sortDirections: ["ascend", "descend"],
  }
}

function cancelledOn(order) {
  if (order.type === "Vendor") {
    return order.updated_at
  }
  if (order.cancellation && order.cancellation["time"]) {
    return order.cancellation["time"]
  }
  return ""
}

function cancelledOnSorter(order) {
  return {
    sorter: (a, b) => (new Date(moment(cancelledOn(a)))).getTime() - (new Date(moment(cancelledOn(b)))).getTime(),
    sortDirections: ['ascend', 'descend']
  }
}

const cancelledReasonString = ({type, cancellation}) => {
  if (type === "Vendor") {
    return "";
  }
  if (cancellation && cancellation["reason"]) {
    return cancellation["reason"];
  }
  return "Unknown"
}

const cancelledReason = (order) => (<span>{cancelledReasonString(order)}</span>);

function cancelledReasonSimple(order) {
  if (order.type === "Vendor") {
    return "";
  }
  if (order.cancellation && order.cancellation["reason"]) {
    return order.cancellation["reason"]
  }
  return "Unknown"
}

function cancelledReasonSorter(order) {
  return {
    sorter: (a, b) => cancelledReasonSimple(a).localeCompare(cancelledReasonSimple(b)),
    sortDirections: ['ascend', 'descend']
  }
}

const cancelledAdminString = ({type, cancellation}) => {
  if (type === "Vendor") {
    return "";
  }
  if (cancellation && cancellation["admin"]) {
    return cancellation["admin"];
  }
  return "Unknown";
}

const cancelledAdmin = (order) => (<span>{cancelledAdminString(order)}</span>)

function cancelledAdminSimple(order) {
  if (order.type === "Vendor") {
    return "";
  }
  if (order.cancellation && order.cancellation["admin"]) {
    return order.cancellation["admin"]
  }
  return "Unknown"
}

function cancelledAdminSorter(order) {
  return {
    sorter: (a, b) => cancelledAdminSimple(a).localeCompare(cancelledAdminSimple(b)),
    sortDirections: ['ascend', 'descend']
  }
}

export {
  cancelledAdmin,
  cancelledAdminSorter,
  cancelledAdminString,
  cancelledOnRender,
  cancelledOnSorter,
  cancelledOnString,
  cancelledReason,
  cancelledReasonSorter,
  cancelledReasonString,
  submittedOnRender,
  unitRender,
  unitSorter,
}
