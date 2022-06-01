import React, {useEffect, useState} from "react";
import { groupPaymentsByDay } from "./groupingFunctions";
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

function chartData(days, total) {
  const data = {
    datasets: [
      {
        data: [
          totalledData(days.early, total), 
          totalledData(days.late, total), 
          totalledData(days.midLate, total), 
          totalledData(days.veryLate, total)
        ],
        backgroundColor: ["#1DBD6B", "#566f75", "#FFC700", "#FD5E20"]
      }
    ],
    labels: ["1st - 5th", "6th - 10th", "11th - 20th", "20th+"]
  }
  return data;
}

// Need to group payments by month and then sum up: one time payments, autopay and moneygram
function paymentsByDay(payments, fetching) {
  const [days, setDays] = useState({early: [], late: [], midLate: [], veryLate: []});
  const [total, setTotal] = useState(false);

  useEffect(() => {
    if (payments.length) {
      const grouped = groupPaymentsByDay(payments);
      return setDays(grouped);
    }
  }, [payments])

  return (
    <Card
      className="w-100"
      title="Payments By Day Of Month"
      extra={(
        <i
          onClick={() => setTotal(!total)}
          className={`float-right cursor-pointer fas fa-${total ? "dollar-sign" : "hashtag"}`}
        />
      )}
    >
      <Spin spinning={fetching}>
        <Pie data={chartData(days, total)} options={{...options(total)}} />
      </Spin>
    </Card>
  )
}

export default paymentsByDay;