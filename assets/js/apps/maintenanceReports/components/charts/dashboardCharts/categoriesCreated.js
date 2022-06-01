import React, {useEffect, useState} from "react";
import {Col, Card, Spin} from "antd";
import {Bar} from "react-chartjs-2";
import axios from "axios";
import {multiBarChartData, multiBarChartSubData} from "./functions";

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

const CategoriesCreatedChart = ({dates, properties}) => {
  const [data, setData] = useState([]);
  const [fetching, setFetching] = useState(false);
  const [chartData, setChartData] = useState({datasets: [], labels: []});
  const [clicked, setClicked] = useState(null);
  const [category, setCategory] = useState(null);
  const [span, setSpan] = useState(12);

  useEffect(() => {
    if (dates && properties && properties.length) {
      const fetchData = async () => {
        setFetching(true);
        const result = await axios(`/api/maintenance_reports?dates=${dates}&properties=${properties}&type=categoriesCreated`);
        setData(result.data);
        setFetching(false);
      };
      fetchData();
    }
  }, [dates[0], dates[1], properties]);

  useEffect(() => {
    if (data.length >= 1) {
      setChartData(multiBarChartData(data));
    }
  }, [data]);

  useEffect(() => {
    const {labels} = multiBarChartData(data);
    if (clicked && clicked.length && !category) {
      // eslint-disable-next-line no-underscore-dangle
      setCategory(labels[(clicked[0]._index)]);
    } else {
      setClicked(null);
      setCategory(null);
      setChartData(multiBarChartData(data));
    }
  }, [clicked]);

  useEffect(() => {
    if (category) setChartData(multiBarChartSubData(data, category));
  }, [category]);

  return (
    <Col span={span}>
      <Card
        className="w-100"
        bordered={false}
        title="Created by Category"
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
          <Bar data={chartData} getElementAtEvent={setClicked} options={{...options("Created by Category")}} />
        </Spin>
      </Card>
    </Col>
  );
};

export default CategoriesCreatedChart;
