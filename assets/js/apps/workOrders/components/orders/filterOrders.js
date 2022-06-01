import React from 'react';
import moment from 'moment';
import {safeRegExp} from "../../../../utils";

const DEFAULT = {unassigned: [], assigned: [], completed: [], cancelled: [], outsourced: []}

function filterOrders(orders, tags, dates) {
  if (!orders) return DEFAULT;
  const {unassigned, assigned, cancelled, completed} = orders;
  return {
    unassigned: filterArray(unassigned, tags, dates),
    assigned: filterArray(assigned, tags, dates),
    completed: filterArray(completed, tags, dates),
    cancelled: filterArray(cancelled, tags, dates)
  }
}

function filterArray(orders, tags, dates) {
  if (!orders) return [];
  return orders.filter(o => checkOrder(o, tags, dates));
}

function checkOrder(order, tags, dates) {
  if (tags.length === 0) return true;
  const checked = tags.map(t => checkTag(order, t));
  return checked.every(t => t === true)
}

function checkTag(order, tag) {
  const filter = safeRegExp(tag);
  return filter.test(order.category) || filter.test(order.parent_category) ||
    filter.test(order.property) || checkType(order, filter) || checkUnit(order, filter) ||
    filter.test(order.ticket) || checkTenant(order, filter) || checkAssignment(order, filter) ||
    checkCancellation(order, filter) || checkPriority(order, filter) || checkVendor(order, filter)
}

function checkVendor(order, filter) {
  if (order.type === "Vendor") return filter.test(order.vendor.name);
  if (order.card) return filter.test(order.card[0].tech) || filter.test(order.card[0].vendor) || filter.test(order.card[0].completed_by);
}

function checkType(order, filter) {
  if (filter.test("Outsourced")) return order.type === "Vendor";
  return filter.test(order.type)
}

function checkPriority(order, filter) {
  if (!order.priority) return false;
  if (filter.test("violation") || filter.test("violations")) return order.priority === 3;
  if (filter.test("emergency") || filter.test("emergencies")) return order.priority === 5;
  return false;
}

function checkUnit(order, filter) {
  if (!order.unit) return true;
  return filter.test(order.unit.number);
}

function checkTenant(order, filter) {
  if (!order.tenant) return false;
  return filter.test(`${order.tenant.first_name} ${order.tenant.last_name}`)
}

function checkAssignment(order, filter) {
  if (!order.assignments) return false;
  const a = order.assignments[0];
  return filter.test(a.tech) || filter.test(a.creator) || filter.test(`${a.rating} stars`)
}

function checkCancellation(order, filter) {
  if (!order.cancellation) return false;
  return filter.test(order.cancellation["admin"]) || filter.test(order.cancellation["reason"])
}

function checkDates(o, dates) {
  const startDate = dates[0].utc().startOf('day');
  const endDate = dates[1].utc().endOf('day');
  if (o.status === "completed" && !o.card) {
    return moment(o.assignments[0].completed_at).utc().isBetween(startDate, endDate);
  } else if (o.card && o.card.completed) {
    return moment(o.card.completed).utc().isBetween(startDate, endDate);
  } else {
    return moment(o.inserted_at).utc().isBetween(startDate, endDate);
  }
}

export default filterOrders
