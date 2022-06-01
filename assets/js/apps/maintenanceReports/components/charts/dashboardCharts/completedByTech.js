import React, {useEffect, useState} from "react";
import {Col, Card, Spin} from "antd";
import {Doughnut} from "react-chartjs-2";
import axios from "axios";
import {pieChartData, pieChartSubData} from "./functions";

const options = (techCount) => ({legend: {display: techCount <= 6}});

const CompletedByTechChart = ({dates, properties}) => {
  const [data, setData] = useState([]);
  const [fetching, setFetching] = useState(false);
  const [chartData, setChartData] = useState({datasets: [], labels: [], keys: []});
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
    if (data.length >= 1) setChartData(pieChartData(data));
  }, [data]);

  useEffect(() => {
    const {keys} = pieChartData(data);
    if (clicked && clicked.length && !subcategory) {
      // eslint-disable-next-line no-underscore-dangle
      setSubcategory(keys[(clicked[0]._index)]);
    } else {
      setClicked(null);
      setSubcategory(null);
      setChartData(pieChartData(data));
    }
  }, [clicked]);

  useEffect(() => {
    if (subcategory) {
      setChartData(pieChartSubData(data, subcategory));
    }
  }, [subcategory]);

  const order = data.find((d) => d.tech_id === subcategory);
  const techName = order && (` - ${order.tech_name}`);
  return (
    <Col span={span}>
      <Card
        className="w-100"
        bordered={false}
        title={`Completed By Tech ${subcategory ? techName : ""}`}
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
          <Doughnut
            data={chartData}
            getElementAtEvent={setClicked}
            options={options(chartData.labels.length)}
          />
        </Spin>
      </Card>
    </Col>
  );
};

export default CompletedByTechChart;
