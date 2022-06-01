import React, {useEffect, useState} from "react";
import moment from "moment";
import {Card, Spin} from "antd";
import {Bar} from "react-chartjs-2";
import {toCurr} from "../../../../utils";

// Expenses will be a dataset, when we have budget info we will add that as a dataset.
// Labels will be the months taken from the passed in data.
// There will be one color per dataset.
// Some way to insure that labels are displayed in oldest first.
// data will be an array of objects, {x: month, y: sum(amounts)}.
// Which is the sum of all the approvals for the given month with a status of approved.
function chartDataFunction(months, setData) {
  const data = {
    datasets: [{
      data: [],
      backgroundColor: "#695dbd",
      borderColor: "#5dbd77",
    }],
    labels: [],
  };
  months.forEach((m) => {
    const sum = m.approvals.filter(a => a.status === "approved").reduce((acc, a) => acc + a.params["amount"], 0)
    data.labels.push(moment(m.month).format("MMM YY"));
    return data.datasets[0].data.push({x: moment(m.month).format("MMM YY"), y: sum});
  });
  return setData(data);
}

function options(title) {
  return {
    plugins: {
      labels: {
        render: "label",
      },
    },
    tooltips: {
      callbacks: {
        label(tooltipItem) {
          return toCurr(tooltipItem.value);
        },
      },
    },
    legend: {
      display: false,
    },
    title: {
      display: false,
      text: title,
    },
    scales: {
      yAxes: [{
        ticks: {
          callback(value) {
            return toCurr(value);
          },
        },
      }],
    },
  };
}

const OverallHistoryChart = ({months, fetching}) => {
  const [data, setData] = useState([]);
  const [locked, setLocked] = useState(false);

  useEffect(() => {
    if (months.length >= 1 && !locked) {
      chartDataFunction(months, setData);
    }
  }, [months]);

  return (
    <Card
      className="w-100"
      bordered={locked}
      title="Monthly Expenses"
      extra={(
        <i
          role="button"
          aria-hidden
          aria-label="lock"
          onClick={() => setLocked(!locked)}
          className={`float-right cursor-pointer fas fa-${locked ? "lock" : "lock-open"}`}
        />
      )}
    >
      <Spin spinning={fetching}>
        <Bar data={data} options={{...options("Stuff")}} />
      </Spin>
    </Card>
  );
};

export default OverallHistoryChart;
