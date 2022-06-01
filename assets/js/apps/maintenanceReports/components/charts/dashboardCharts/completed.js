import React, {useEffect, useState} from "react";
import {
  Col, Card, Spin, Space,
} from "antd";
import {Line} from "react-chartjs-2";
import axios from "axios";
import {barChartDataFunction, reducedProperties} from "./functions";

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

const CompletedChart = ({dates, properties, windowProperties}) => {
  const [data, setData] = useState([]);
  const [fetching, setFetching] = useState(false);
  const [chartData, setChartData] = useState({datasets: [], labels: []});
  const [span, setSpan] = useState(12);

  useEffect(() => {
    if (dates && properties && properties.length) {
      const fetchData = async () => {
        setFetching(true);
        const result = await axios(`/api/maintenance_reports?dates=${dates}&properties=${properties}&type=completed`);
        setData(result.data);
        setFetching(false);
      };
      fetchData();
    }
  }, [dates[0], dates[1], properties]);

  useEffect(() => {
    if (data.length >= 1) {
      setChartData(barChartDataFunction(reducedProperties(data), windowProperties));
    }
  }, [data]);

  return (
    <Col span={span}>
      <Card
        className="w-100"
        bordered={false}
        title="Completed Work Orders"
        extra={(
          <Space size="small">
            <i
              role="button"
              aria-hidden
              aria-label="Expand"
              onClick={() => setSpan(span === 12 ? 24 : 12)}
              className={`float-right cursor-pointer fas fa-${span === 12 ? "expand" : "compress"}`}
            />
          </Space>
        )}
      >
        <Spin spinning={fetching}>
          <Line data={chartData} options={{...options("Completed Work Orders")}} />
        </Spin>
      </Card>
    </Col>
  );
};

export default CompletedChart;
