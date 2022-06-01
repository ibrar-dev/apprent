import React, {useEffect, useState} from "react";
import {Col, Card, Spin} from "antd";
import {Doughnut} from "react-chartjs-2";
import axios from "axios";
import colors from "../../../../usageDashboard/components/colors";
import {pieChartData} from "./functions";
const options = {
  plugins: {labels: {render: "label"}},
  title: {display: false, text: "Prio"},
};
const categories = [
  {label: "Call Back", key: "callback", backgroundColor: "#6c757d"},
  {label: "Emergency", key: "emergency", backgroundColor: "#dc3545"},
  {label: "Violation", key: "violation", backgroundColor: "#ffc107"},
  {label: "Regular", key: "regular", backgroundColor: "#28a745"},
];
const labels = categories.map((c) => c.label);
const buildClickedData = (d, clicked) => {
  const filtered = d[categories[clicked].key];
  return pieChartData(filtered, "category", "category");
};
const buildStandardData = (d) => (
  {
    labels,
    datasets: [
      {
        label: "Open Orders",
        backgroundColor: categories.map((c) => c.backgroundColor),
        data: [
          (d.callback ? d.callback.length : 0),
          (d.emergency ? d.emergency.length : 0),
          (d.violation ? d.violation.length : 0),
          (d.regular ? d.regular.length : 0),
        ],
      },
    ],
  }
);
const buildChartData = (d, clicked) => (
  clicked ? buildClickedData(d, clicked) : buildStandardData(d)
);
const formatData = (data) => {
  const callback = [];
  const regular = [];
  const violation = [];
  const emergency = [];
  data.forEach((ord) => {
    const asgnStatus = ord.assignments.map((a) => a.status);
    if (asgnStatus.includes("callback")) {
      callback.push(ord);
    } else {
      switch (ord.priority) {
        case 0:
        case 1:
          regular.push(ord);
          break;
        case 3:
          violation.push(ord);
          break;
        case 5:
          emergency.push(ord);
          break;
        // no default
      }
    }
  });
  return {
    data, callback, regular, violation, emergency,
  };
};
const PriorityChart = ({dates, properties}) => {
  const [data, setData] = useState({});
  const [fetching, setFetching] = useState(false);
  const [clicked, setClicked] = useState(null);
  const [span, setSpan] = useState(12);
  useEffect(() => {
    if (properties && properties.length) {
      const fetchData = async () => {
        setFetching(true);
        const result = await axios(`/api/maintenance_reports?dates=${dates}&properties=${properties}&type=priority`);
        setData(formatData(result.data));
        setFetching(false);
      };
      fetchData();
    }
  }, [properties]);
  // eslint-disable-next-line no-underscore-dangle
  const toggleClicked = (val) => (clicked ? setClicked(null) : setClicked(val[0]._index));
  const title = clicked ? ` - ${labels[clicked]}` : "";
  return (
    <Col span={span}>
      <Card
        className="w-100"
        bordered={false}
        title={`Open Work Orders by Priority ${title}`}
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
            data={buildChartData(data, clicked)}
            getElementAtEvent={toggleClicked}
            options={options}
          />
        </Spin>
      </Card>
    </Col>
  );
};
export default PriorityChart;
