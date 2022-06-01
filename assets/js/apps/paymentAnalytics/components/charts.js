import React, {useEffect, useState} from "react";
import {Row, Col} from "antd";
import axios from "axios";
import paymentsChart from "./charts/paymentsChart";
import paymentsByDateChart from "./charts/paymentsByDateChart";
import paymentsByDay from "./charts/paymentsByDayChart";
import paymentsByMethod from "./charts/paymentMethodChart";
import paymentsBySource from "./charts/paymentSourceChart";
import monthToDateChart from "./charts/monthToDateChart";

function formattedDates(dates) {
  return [dates[0].format("YYYY-MM-DD"), dates[1].format("YYYY-MM-DD")];
}

function charts(properties, dates) {
  const [data, setData] = useState([]);
  const [fetching, setFetching] = useState(false);

  useEffect(() => {
    if (properties && properties.length) {
      const fetchData = async () => {
        setFetching(true);
        const result = await axios(`/api/payments_analytics?charts&properties=${properties}&dates=${formattedDates(dates)}`);
        setData(result.data);
        setFetching(false);
      };
      fetchData();
    }
  }, [properties, dates]);

  return (
    <>
      <Row>
        <Col span={12}>
          {paymentsChart(data, dates, fetching)}
        </Col>
        <Col span={12}>
          {monthToDateChart(data, dates, fetching)}
        </Col>
      </Row>
      <Row>
        <Col span={8}>
          {paymentsByDay(data, fetching)}
        </Col>
        <Col span={8}>
          {paymentsByMethod(data, fetching)}
        </Col>
        <Col span={8}>
          {paymentsBySource(data, fetching)}
        </Col>
      </Row>
      <Row>
        <Col span={24}>
          {paymentsByDateChart(data, fetching)}
        </Col>
      </Row>
    </>
  )
}

export default charts;