import React, {useEffect, useState} from "react";
import {Doughnut} from "react-chartjs-2";
import colors from "../../../usageDashboard/components/colors";
import {toCurr, titleize} from "../../../../utils";

// Iterate through the list of approvals_analytics
// |> filter out by type
// |> go through each one and pass into obecjt where each category has a value.
// |> for each one that matches the value incrase the parseFloat of that cost
// |> each category should also push a backgroundColor and hoverBackgroundColor
function pieChartDataFunction(approvals, setData, type) {
  const data = {
    datasets: [{
      data: [],
      backgroundColor: [],
      hoverBackgroundColor: [],
      borderColor: [],
    }],
    labels: [],
  };
  const agg = {};
  approvals.filter((a) => a.status === type).forEach((a) => {
    return a.costs.forEach((c) => {
      if (agg[a.payee]) {
        agg[a.payee] += parseFloat(c.amount);
      } else {
        agg[a.payee] = parseFloat(c.amount);
      }
    });
  });
  Object.keys(agg).forEach((k, i) => {
    const col = colors(i, Object.keys(agg).length);
    data.labels.push(k);
    data.datasets[0].data.push(agg[k]);
    data.datasets[0].backgroundColor.push(col.replace(/, .*\)/, ",0.8)"));
    data.datasets[0].hoverBackgroundColor.push(col);
    data.datasets[0].borderColor.push(col.replace(/, .*\)/, ",0.2)"));
  });
  return setData(data)
}

function options(length) {
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
          return toCurr(data.datasets[0].data[tooltipItem.index]);
        },
      },
    },
    legend: {
      display: length <= 10,
    },
  };
}

const PayeeChart = ({approvals}) => {
  const [data, setData] = useState({labels: []});
  const [type, setType] = useState("approved");

  useEffect(() => {
    if (approvals && approvals.length) {
      pieChartDataFunction(approvals, setData, type);
    }
  }, [approvals]);

  return (
    <Doughnut data={data} options={{...options(data.labels.length)}} />
  );
};

export default PayeeChart;
