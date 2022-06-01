import React, {useEffect, useState} from "react";
import { groupPaymentsBySource } from "./groupingFunctions";
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

function chartData(sources, total) {
  const data = {
    datasets: [
      {
        data: [
          totalledData(sources.web, total), 
          totalledData(sources.app, total), 
          totalledData(sources.moneygram, total),
          totalledData(sources.text, total)
        ],
        backgroundColor: ["#1DBD6B", "#566f75", "#FFC700", "#FD5E20"]
      }
    ],
    labels: ["Website", "Mobile App", "MoneyGram", "TextPay"]
  }
  return data;
}

// Need to group payments by month and then sum up: one time payments, autopay and moneygram
function paymentsBySource(payments, fetching) {
  const [sources, setSources] = useState({web: [], app: [], moneygram: [], text: []});
  const [total, setTotal] = useState(false);

  useEffect(() => {
    if (payments.length) {
      const grouped = groupPaymentsBySource(payments);
      return setSources(grouped);
    }
  }, [payments])
  
  return (
    <Card
      className="w-100"
      title="Payments By Source"
      extra={(
        <i
          onClick={() => setTotal(!total)}
          className={`float-right cursor-pointer fas fa-${total ? "dollar-sign" : "hashtag"}`}
        />
      )}
    >
      <Spin spinning={fetching}>
        <Pie data={chartData(sources, total)} options={{...options(total)}} />
      </Spin>
    </Card>
  )
}

export default paymentsBySource;