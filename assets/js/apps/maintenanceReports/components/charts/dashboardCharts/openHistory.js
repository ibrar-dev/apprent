import React, {useEffect, useState} from "react";
import {Col, Card, Spin} from "antd";
import {Line} from "react-chartjs-2";
import axios from "axios";
import {barChartDataFunctionOpen, reducedPropertiesOpen} from "./functions";

function options(title) {
  return {
    plugins: {
      labels: {
        render: "label",
      },
    },
    title: {
      display: false,
      text: title,
    },
  };
}

const OpenHistoryChart = ({dates, properties, windowProperties}) => {
  const [data, setData] = useState([]);
  const [fetching, setFetching] = useState(false);
  const [chartData, setChartData] = useState({datasets: [], labels: []});
  const [span, setSpan] = useState(12);

  useEffect(() => {
    if (dates && properties && properties.length) {
      const fetchData = async () => {
        setFetching(true);
        const result = await axios(`/api/maintenance_reports?dates=${dates}&properties=${properties}&type=open`);
        setData(result.data);
        setFetching(false);
      };
      fetchData();
    }
  }, [dates[0], dates[1], properties]);

  useEffect(() => {
    if (data.length >= 1) {
      setChartData(barChartDataFunctionOpen(reducedPropertiesOpen(data), windowProperties));
    }
  }, [data]);

  return (
    <Col span={span}>
      <Card
        className="w-100"
        bordered={false}
        title="Open Work Orders"
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
          <Line data={chartData} options={{...options("Open Work Orders")}} />
        </Spin>
      </Card>
    </Col>
  );
};

export default OpenHistoryChart;
