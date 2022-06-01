import React from 'react';
import moment from 'moment';
import actions from "../../../actions";

// `order.assignments` can sometimes be null; in either case, we want the first
// assignment, which in some cases will be an empty JSON object literal.
function getAssignment(order) {
  const assignments = order.assignments || []
  return assignments[0] || {}
}

const assignedAtTimeString = (order) => {
  const timeSource = order.type === "Vendor" ? order : getAssignment(order);
  return moment(timeSource.inserted_at).utc().local().format("MM/DD/YY h:mmA")
};

const assignedAtRenderer = (order) => (<span>{assignedAtTimeString(order)}</span>);

function assignedAtSorter() {
  return {
    sorter: (a, b) => (new Date(moment(a.inserted_at))).getTime() - (new Date(moment(b.inserted_at))).getTime(),
    sortDirections: ['ascend', 'descend']
  }
}

function getAssignedCard(card) {
  if (card.tech) return `${card.tech} - Tech`;
  if (card.vendor) return `${card.vendor} - Outsource`;
  if (card.completed_by) return `${card.completed_by} - Admin`;
  return "N/A"
}

function getAssignedTo(order) {
  if (order.type === "Vendor") return order.vendor.name;
  if (order.card) return getAssignedCard(order.card[0]);
  return getAssignment(order).tech
}

function assignedToSorter() {
  return {
    sorter: (a, b) => getAssignedTo(a).localeCompare(getAssignedTo(b)),
    sortDirections: ['ascend', 'descend']
  }
}

function assignedToRenderer(order) {
  if (order.type === "Vendor") {
    return <span>{order.vendor.name}</span>
  }
  if (order.card) {
    return <span>{getAssignedCard(order.card[0])}</span>
  }
  return (
    <a
      href={`/techs/${getAssignment(order).tech_id}`}
      target={"_blank"}
    >
      {getAssignment(order).tech}
    </a>
  )
}

function clickableCell(record) {
  return {
    onClick: () => actions.setOrderData(record)
  }
}


export {
  assignedAtRenderer,
  assignedAtTimeString,
  assignedToRenderer,
  clickableCell,
  assignedToSorter,
  assignedAtSorter,
  getAssignedTo,
}
