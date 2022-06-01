import React from 'react';
import {Rate} from "antd";
import moment from 'moment';

function ratingRender(assignments) {
  if (!assignments) return <span>N/A</span>
  const a = assignments[0];
  if (!a.rating) return <span>Not Yet Rated</span>
  return <Rate disabled defaultValue={a.rating} />
}

const completedAtString = ({type, card, updated_at, assignments}) => {
  if (type === "Vendor") return moment.utc(updated_at).local().format("MM/DD/YY h:mmA");
  if (card && card[0].completed) moment(card[0].completed).format("MM/DD/YY");
  const a = assignments[0];
  if (!a || !a.completed_at) return "N/A"
  return moment.utc(a.completed_at).local().format("MM/DD/YY h:mmA")
}

const completedAtRender = (order) => (<span>{completedAtString(order)}</span>);

const timeOpenString = ({type, card, updated_at, creation_date, inserted_at, assignments}) => {
  if (type === "Vendor") return <span>{moment(updated_at).utc().to(moment(creation_date), true)}</span>
  if (card && card[0].completed) return <span>{moment(card[0].completed).to(moment(inserted_at).utc(), true)}</span>
  return moment(assignments[0].completed_at).utc().to(moment(inserted_at).utc(), true)
}

const timeOpen = (order) => (<span>{timeOpenString(order)}</span>);

function timeOpenMS(order) {
	if (order.type === "Vendor") return moment.utc(order.updated_at).diff(moment(order.creation_date))
	if (order.card && order.card[0].completed) return moment(order.card[0].completed).diff(moment.utc(order.inserted_at))
	const a = order.assignments[0];
	return moment.utc(a.completed_at).diff(moment.utc(order.inserted_at))
}

function getCompletedAt(order) {
  if (order.type === "Vendor") return order.updated_at
  if (order.card && order.card[0].completed) return order.card[0].completed
  const a = order.assignments[0];
  if (!a || !a.completed_at) return ""
  return a.completed_at
}

function daysIncompleteSorter() {
  return {
    sorter: (a, b) => timeOpenMS(a) - timeOpenMS(b),
    sortDirections: ['ascend', 'descend']
  }
}

function completedDateSorter() {
  return {
    sorter: (a, b) => (new Date(moment(getCompletedAt(a)))).getTime() - (new Date(moment(getCompletedAt(b)))).getTime(),
    sortDirections: ['ascend', 'descend']
  }
}

function getRating(order) {
  if (!order.assignments) return 0;
  const a = order.assignments[0];
  if (!a.rating) return 0;
  return a.rating
}

function ratingSorter() {
  return {
    sorter: (a, b) => getRating(a) - getRating(b),
    sortDirections: ['ascend', 'descend']
  }
}

export {
  ratingRender,
  completedAtRender,
  timeOpen,
  completedDateSorter,
  ratingSorter,
  daysIncompleteSorter,
  completedAtString,
  timeOpenString,
}
