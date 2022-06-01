import React, {useEffect, useState} from "react";
import { groupPaymentsByMonth, sumOrTotalOfPayments } from "./groupingFunctions";
import moment from "moment";
import {Card, Spin} from "antd";
import {Bar} from "react-chartjs-2";
import { toCurr, titleize } from "../../../../utils";

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

function chartData(months, total) {
  const data = {
    datasets: [
      {
        data: months.map((m) => sumOrTotalOfPayments(m.payments, total)),
        borderColor: "#1DBD6B",
        backgroundColor: "#04333B"
      }
    ],
    labels: months.map((m) => m.month)
  }
  return data;
}

// This function will handle removing any payments that were made in prior months after the date of the month.
function filterAppropriatePaymentsMTD(months, dates) {
  const dayOfMonth = moment(dates[1]).date();
  return months.map((m) => {
    return {month: moment(m.month).format(`MM/${dayOfMonth}/YY`), payments: m.payments.filter((p) => moment(p.inserted_at).date() <= dayOfMonth)}
  })
}

// Need to group payments by month and then display what the MTD payments were on previous months.
function monthToDateChart(payments, dates, fetching) {
  const [months, setMonths] = useState([]);
  const [total, setTotal] = useState(true);

  useEffect(() => {
    if (payments.length) {
      const grouped = groupPaymentsByMonth(payments, dates);
      const filtered = filterAppropriatePaymentsMTD(grouped, dates);
      return setMonths(filtered);
    }
  }, [payments]);

  return (
    <Card
      className="w-100"
      title="AppRent Payments MTD Comparison"
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

export default monthToDateChart;