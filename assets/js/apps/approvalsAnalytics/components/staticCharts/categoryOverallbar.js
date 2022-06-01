import React, {useEffect, useState} from "react";
import {Col, Card, Spin} from "antd";
import moment from "moment";
import {toCurr} from "../../../../utils";
import {HorizontalBar} from "react-chartjs-2";
import colors from "../../../usageDashboard/components/colors";

//Only approved, each dataset is a category with an array of value for each month.
//Each category has its own dataset with its own label.
//Each dataset has an array data with the sum of the approved amounts for that category.
//Each dataset also has one label with the name of the category.
function chartDataFunction(months, setData) {
  const data = {
    datasets: [],
    labels: []
  };
  const monthsCategories = {};
  const categories = [];
  months.forEach(m => {
    m.approvals.filter(a => a.status === "approved").forEach(a => {
      a.costs.forEach(cost => {
        if (categories.indexOf(cost.category) === -1) categories.push(cost.category);
        if (monthsCategories[cost.category] && monthsCategories[cost.category][m.month]) {
          return monthsCategories[cost.category][m.month].push(cost.amount);
        } else if (monthsCategories[cost.category] && !monthsCategories[cost.category][m.month]) {
          return monthsCategories[cost.category][m.month] = [cost.amount]
        } else {
          return monthsCategories[cost.category] = {[m.month]: []}
        }
      });
    })
    data.labels.push(moment(m.month).format("MMM YY"));
  })
  const {length} = Object.keys(categories);
  Object.keys(monthsCategories).forEach((k, i) => {
    const vData = []
    const col = colors(i, length);
    Object.keys(monthsCategories[k]).forEach(vk => {
      if (monthsCategories[k][vk].length) {
        return vData.push({y: moment(vk).format("MMM YY"), x: monthsCategories[k][vk].reduce((acc, c) => acc + parseFloat(c), 0)})
      }
    });
    return data.datasets.push({
      label: k,
      data: vData,
      backgroundColor: col.replace(/, .*\)/, ",0.5)"),
      borderColor: col
    });
  })
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
        label: function(tooltipItem, data) {
          return `${data.datasets[tooltipItem.datasetIndex].label} - ${toCurr(tooltipItem.value)}`;
        }
      }
    },
    legend: {
      display: true,
    },
    title: {
      display: false,
      text: title,
    },
    scales: {
      xAxes: [{
        ticks: {
          callback(value) {
            return toCurr(value);
          }
        },
      }],
    },
  };
}

const CategoryOverallChart = ({months, fetching}) => {
  const [data, setData] = useState([]);
  const [locked, setLocked] = useState(false);

  useEffect(() => {
    if (months.length >= 1 && !locked) {
      chartDataFunction(months, setData)
    }
  }, [months]);

  return (
    <Card
      className="w-100"
      bordered={locked}
      title="By Category"
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
        <HorizontalBar data={data} options={{...options("Stuff")}} />
      </Spin>
    </Card>
  )
}

export default CategoryOverallChart
