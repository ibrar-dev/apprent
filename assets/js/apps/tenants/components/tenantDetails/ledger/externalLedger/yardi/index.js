import React from "react";
import {Table} from "antd";
import {
  dateRender, 
  descriptionRender, 
  chargeRender, 
  paymentRender, 
  balanceRender, 
  notesRender, 
  idRender
} from "./entryRenders"
import { toCurr } from "../../../../../../../utils";

const columns = [
  {title: "Date", render: (e) => (dateRender(e))},
  {title: "Description", render: (e) => (descriptionRender(e))},
  {title: "Charge", render: (e) => (chargeRender(e))},
  {title: "Payment", render: (e) => (paymentRender(e))},
  {title: "Balance", render: (e) => (balanceRender(e))},
  {title: "Notes", render: (e) => (notesRender(e))},
  {title: "ID", render: (e) => (idRender(e))}
]

function runningBalanceMap(entries) {
  let startingBalance = 0;
  return entries.map((e, i) => {
    const currentBalance = parseFloat(startingBalance) + calculateAmount(e);
    startingBalance = currentBalance
    return currentBalance;
  })
}

function calculateAmount(entry) {
  if (entry.type === "payment") {
    return parseFloat(entry.amount) * -1
  }
  return parseFloat(entry.amount);
}

function syncButton() {
  
}

function titleComponent(runningBalance, currentLease) {
  return <div className="d-flex justify-content-between">
    <h5>Balance: {toCurr(runningBalance[runningBalance.length - 1])}</h5>
    <div></div>
  </div>
}

function yardiLedger(entries) {
  const runningBalance = runningBalanceMap(entries);

  const mergedEntries = entries.map((e, i) => {
    return {...e, balance: runningBalance[i]};
  })

  return (
    <>
      <Table 
        title={() => titleComponent(runningBalance, {})}
        size="small"
        className="w-100"
        columns={columns}
        pagination={false}
        dataSource={mergedEntries}
        rowKey={(record) => record.transaction_id}
      />
    </>
  )
}

export default yardiLedger; 