import React, {useEffect, useState} from "react";
import {Row, Col} from "antd";
import moment from "moment";
import OverallHistoryChart from "./overallHistory";
import CategoryOverallChart from "./categoryOverallbar";

function sortByMonth(approvals, dates, setMonths) {
  const startDate = dates[0].startOf("month").clone();
  const endDate = dates[1];
  const months = [];
  while (endDate > startDate || startDate.format("M") === endDate.format("M")) {
    months.push({month: startDate.format("MM/DD/YYYY"), approvals: []});
    startDate.add(1, "month");
  }
  approvals.forEach((a) => {
    const month = moment(a.inserted_at).startOf("month").format("MM/DD/YYYY");
    const index = months.findIndex((m) => m.month === month);
    return months[index].approvals.push(a);
  })
  return setMonths(months);
}

const StaticCharts = ({data, dates, fetching}) => {
  const [months, setMonths] = useState([]);

  useEffect(() => {
    if (data.length) return sortByMonth(data, dates, setMonths);
  }, [data])

  return (
    <Row>
      <Col span={12}>
        <OverallHistoryChart months={months} fetching={fetching} />
      </Col>
      <Col span={12}>
        <CategoryOverallChart months={months} fetching={fetching} />
      </Col>
    </Row>
  );
};

export default StaticCharts
