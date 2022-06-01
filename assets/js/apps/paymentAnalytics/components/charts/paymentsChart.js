import React, {useEffect, useState} from "react";
import { groupPaymentsByMonth, getSumOfType, sumOrTotalOfPayments } from "./groupingFunctions";
import moment from "moment";
import {Card, Spin} from "antd";
import {Bar} from "react-chartjs-2";
import { toCurr, titleize } from "../../../../utils";

function sumMonths(months) {
  return months.map((m) => {
    return {
      ...m, 
      one_time: getSumOfType(m.payments, "one_time"), 
      autopay: getSumOfType(m.payments, "autopay"),
      moneygram: getSumOfType(m.payments, "moneygram"),
      text: getSumOfType(m.payments, "text")
    }
  })
}

function sumUpMonth(datasets, index) {
  const monthTotal = 
    datasets.map((d) => d.data[index])
    .reduce((t, acc) => {
      return t + acc;
    }, 0)
  return monthTotal
}

function options(total) {
  return {
    plugins: {
      labels: {
        render: "label",
      },
    },
    tooltips: {
      callbacks: {
        title(tooltipItem, data) {
          let monthTotal = sumUpMonth(data.datasets, tooltipItem[0].index);
          if (total) monthTotal = toCurr(monthTotal);
          return [titleize(data.labels[tooltipItem[0].index]), monthTotal];
        },
        label(tooltipItem, data) {
          if (total) return toCurr(data.datasets[tooltipItem.datasetIndex].data[tooltipItem.index])
          return data.datasets[tooltipItem.datasetIndex].data[tooltipItem.index];
        },
      },
    },
    legend: {
      position: "bottom",
    },
    title: {
      display: false,
    },
    scales: {
      xAxes: [{
        stacked: true
      }],
      yAxes: [{
        stacked: true,
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

function chartData(months, total) {
  const data = {
    datasets: [
      {
        data: months.map((m) => sumOrTotalOfPayments(m.one_time, total)),
        label: "One Time",
        order: 0,
        backgroundColor: "#566f75",
        borderColor: "#755f56"
      },
      {
        data: months.map((m) => sumOrTotalOfPayments(m.autopay, total)),
        label: "AutoPay",
        order: 0,
        backgroundColor: "#1dbd6b",
        borderColor: "#bd301d"
      },
      {
        data: months.map((m) => sumOrTotalOfPayments(m.moneygram, total)),
        label: "MoneyGram",
        order: 0,
        backgroundColor: "#FFC700",
        borderColor: "#20e3fd"
      },
      {
        data: months.map((m) => sumOrTotalOfPayments(m.text, total)),
        label: "TextPay",
        order: 0,
        backgroundColor: "#FD5E20",
        borderColor: "#20e3fd"
      }
    ],
    labels: months.map((m) => moment(m.month).format("MMM YYYY"))
  }
  return data;
}

function paymentsChart(payments, dates, fetching) {
  const [months, setMonths] = useState([]);
  const [total, setTotal] = useState(true);

  useEffect(() => {
    if (payments.length) {
      const grouped = groupPaymentsByMonth(payments, dates);
      const sums = sumMonths(grouped);
      return setMonths(sums);
    }
  }, [payments])

  return (
    <Card
      className="w-100"
      title="AppRent Payments"
      extra={(
        <i
          onClick={() => setTotal(!total)}
          className={`float-right cursor-pointer fas fa-${total ? "dollar-sign" : "hashtag"}`}
        />
      )}
    >
      <Spin spinning={fetching}>
        <Bar data={chartData(months, total)} options={{...options(total)}} />
      </Spin>
    </Card>
  )
}

export default paymentsChart;