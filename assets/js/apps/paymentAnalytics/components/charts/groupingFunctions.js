import React from "react";
import moment from "moment";

function groupPaymentsByMonth(payments, dates) {
  const startDate = dates[0].startOf("month").clone();
  const endDate = dates[1];
  const months = [];
  while (endDate > startDate || startDate.format("M") === endDate.format("M")) {
    months.push({month: startDate.format("MM/DD/YYYY"), payments: []});
    startDate.add(1, "month");
  }
  payments.forEach((p) => {
    const month = moment(p.inserted_at).startOf("month").format("MM/DD/YYYY");
    const index = months.findIndex((m) => m.month === month);
    return months[index].payments.push(p);
  })
  return months;
}

function groupPaymentsByDate(payments) {
  let dates = {};
  payments.forEach((p) => {
    const date = moment(p.inserted_at).format("MM/DD/YYYY");
    if (dates[date]) return dates[date].push(p);
    return dates[date] = [p]
  })
  return dates;
}

function getSumOfType(payments, type) {
  const oneTimeSources = ["web", "mobile", "site", "text"];
  return payments.filter((p) => {
    if (p.source === type) return true;
    if (type === "one_time" && oneTimeSources.includes(p.source)) return true;
    return false;
  })
}

// website, mobile app, moneygram
function groupPaymentsBySource(payments) {
  let web = [];
  let app = [];
  let moneygram = [];
  let text = [];
  payments.forEach((p) => {
    if (p.source === "moneygram") return moneygram.push(p);
    if (p.source === "web") return web.push(p);
    if (p.source === "mobile") return app.push(p);
    if (p.source === "text") return text.push(p);
    return 
  })
  return {web, app, moneygram, text}
}

function groupPaymentsByMethod(payments) {
  let cc = [];
  let ach = [];
  let moneygram = [];
  let others = [];
  payments.forEach((p) => {
    if (p.source === "moneygram") return moneygram.push(p);
    if (p.source_type === "ba") return ach.push(p);
    if (p.source_type === "cc") return cc.push(p);
    console.log(`Condition Not Met - ${p.id}`)
    return others.push(p);
  })
  return {cc, ach, moneygram, others}
}

// 1-5th, 6-10, 11-20, 20+
function groupPaymentsByDay(payments) {
  let early = [] 
  let late = []
  let midLate = []
  let veryLate = [];
  payments.forEach((p) => {
    const dayOfMonth = moment(p.inserted_at).date();
    if (dayOfMonth < 5) return early.push(p);
    if (dayOfMonth < 10) return late.push(p);
    if (dayOfMonth < 20) return midLate.push(p);
    return veryLate.push(p);
  })
  return {
    early,
    late,
    midLate,
    veryLate
  }
}

function sumOrTotalOfPayments(payments, total) {
  if (total) {
    return payments.reduce((acc, p) => {
      return acc + parseFloat(p.amount);
    }, 0)
  } else {
    return payments.length;
  }
}

export {
  groupPaymentsByMonth,
  groupPaymentsBySource,
  getSumOfType,
  groupPaymentsByDay,
  groupPaymentsByMethod,
  groupPaymentsByDate,
  sumOrTotalOfPayments
}