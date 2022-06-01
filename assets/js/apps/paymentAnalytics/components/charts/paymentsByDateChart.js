import React, {useEffect, useState} from "react";
import { groupPaymentsByDate, sumOrTotalOfPayments } from "./groupingFunctions";
import {Card, Spin} from "antd";
import {Line} from "react-chartjs-2";
import { toCurr, titleize } from "../../../../utils";

function options(total) {
  return {
    plugins: {
      labels: {
        render: "label",
      },
    },
    ticks: {
      autoSkip: true
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
    legend: {
      display: false,
      position: "bottom",
    },
    line: {
      fill: false
    },
    title: {
      display: false
    },
    scales: {
      yAxes: [{
        ticks: {
          callback(value) {
            if (total) return toCurr(value);
            return value; 
          },
          beginAtZero: true
        },
      }],
    },
  };
}

function readObjectOfData(dates, total) {
  let labels = [];
  let values = [];
  Object.entries(dates).map(([key, value]) => {
    labels.push(key);
    let sum;
    sum = sumOrTotalOfPayments(value, total);
    return values.push(sum);
  })
  return {labels, values}
}

function chartData(dates, total) {
  const arrayified = readObjectOfData(dates, total);
  const data = {
    datasets: [
      {
        data: arrayified.values,
        borderColor: "#04333B",
        backgroundColor: "#1DBD6B",
        steppedLine: 'middle'
      }
    ],
    labels: arrayified.labels
  }
  return data;
}

// Need to group payments by month and then sum up: one time payments, autopay and moneygram
function paymentsByDateChart(payments, fetching) {
  const [dates, setDates] = useState({});
  const [total, setTotal] = useState(true);

  useEffect(() => {
    if (payments.length) {
      const grouped = groupPaymentsByDate(payments, dates);
      return setDates(grouped);
    }
  }, [payments])
  

  return (
    <Card
      className="w-100"
      title="AppRent Payments By Date"
      extra={(
        <i
          onClick={() => setTotal(!total)}
          className={`float-right cursor-pointer fas fa-${total ? "dollar-sign" : "hashtag"}`}
        />
      )}
    >
      <Spin spinning={fetching}>
        <Line data={chartData(dates, total)} options={{...options(total)}} />
      </Spin>
    </Card>
  )
}

export default paymentsByDateChart;