import React, {useEffect, useState} from "react";
import {Col, Card, Spin} from "antd";
import {Bar} from "react-chartjs-2";
import axios from "axios";
import {chartDataFunction, scChartDataFunction} from "./functions";

function options(title) {
  return {
    plugins: {
      labels: {
        render: "label",
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
          beginAtZero: true,
          precision: 0,
        },
      }],
    },
  };
}

const CategoriesCompletedChart = ({dates, properties}) => {
  const [data, setData] = useState([]);
  const [fetching, setFetching] = useState(false);
  const [chartData, setChartData] = useState({datasets: [], labels: []});
  const [clicked, setClicked] = useState(null);
  const [subcategory, setSubcategory] = useState(null);
  const [span, setSpan] = useState(12);

  useEffect(() => {
    if (dates && properties && properties.length) {
      const fetchData = async () => {
        setFetching(true);
        const result = await axios(`/api/maintenance_reports?dates=${dates}&properties=${properties}&type=categoriesCompleted`);
        setData(result.data);
        setFetching(false);
      };
      fetchData();
    }
  }, [dates[0], dates[1], properties]);

  useEffect(() => {
    if (data.length >= 1) {
      setChartData(chartDataFunction(data));
    }
  }, [data]);

  useEffect(() => {
    const {labels} = chartDataFunction(data);
    if (clicked && clicked.length && !subcategory) {
      setSubcategory(labels[(clicked[0]._index)]);
    } else {
      setClicked(null);
      setSubcategory(null);
      setChartData(chartDataFunction(data));
    }
  }, [clicked]);

  useEffect(() => {
    if (subcategory) {
      setChartData(scChartDataFunction(data, subcategory));
    }
  }, [subcategory]);

  return (
    <Col span={span}>
      <Card
        className="w-100"
        bordered={false}
        title="Completed by Category"
        extra={(
          <i
            role="button"
            aria-hidden
            aria-label="Expand"
            onClick={() => setSpan(span === 12 ? 24 : 12)}
            className={`float-right cursor-pointer fas fa-${span === 12 ? "expand" : "compress"}`}
          />
        )}
      >
        <Spin spinning={fetching}>
          <Bar data={chartData} getElementAtEvent={setClicked} options={{...options("Completed by Category")}} />
        </Spin>
      </Card>
    </Col>
  );
};

export default CategoriesCompletedChart;
