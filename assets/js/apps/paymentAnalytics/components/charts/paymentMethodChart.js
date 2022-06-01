import React, {useEffect, useState} from "react";
import { groupPaymentsByMethod } from "./groupingFunctions";
import {Card, Spin} from "antd";
import {Pie} from "react-chartjs-2";
import { toCurr, titleize } from "../../../../utils";

function options(total) {
  return {
    legend: {
      position: "bottom",
    },
    tooltips: {
      callbacks: {
        title(tooltipItem, data) {
          return titleize(data.labels[tooltipItem[0].index]);
        },
        label(tooltipItem, data) {
          if (total) return toCurr(data.datasets[0].data[tooltipItem.index])
          return data.datasets[0].data[tooltipItem.index];
        },
      },
    },
    title: {
      display: false
    }
  };
}

function totalledData(payments, total) {
  if (total) {
    return payments.reduce((acc, p) => {
      return acc + parseFloat(p.amount)
    }, 0);
  } else {
    return payments.length;
  } 
}

function chartData(types, total) {
  const data = {
    datasets: [
      {
        data: [
          totalledData(types.cc, total), 
          totalledData(types.ach, total), 
          totalledData(types.moneygram, total)
        ],
        backgroundColor: ["#1DBD6B", "#566f75", "#FFC700"]
      }
    ],
    labels: ["Credit Card", "ACH", "MoneyGram"]
  }
  return data;
}

// Need to group payments by month and then sum up: one time payments, autopay and moneygram
function paymentsByMethod(payments, fetching) {
  const [types, setTypes] = useState({cc: [], ach: [], moneygram: []});
  const [total, setTotal] = useState(false);

  useEffect(() => {
    if (payments.length) {
      const grouped = groupPaymentsByMethod(payments);
      return setTypes(grouped);
    }
  }, [payments])
  

  return (
    <Card
      className="w-100"
      title="Payments By Payment Method"
      extra={(
        <i
          onClick={() => setTotal(!total)}
          className={`float-right cursor-pointer fas fa-${total ? "dollar-sign" : "hashtag"}`}
        />
      )}
    >
      <Spin spinning={fetching}>
        <Pie data={chartData(types, total)} options={{...options(total)}} />
      </Spin>
    </Card>
  )
}

export default paymentsByMethod;