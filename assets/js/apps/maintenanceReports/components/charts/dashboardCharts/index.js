import React from "react";
import {Row} from "antd";
import Completed from "./completed";
import OpenHistoryChart from "./openHistory";
import CategoriesCompletedChart from "./categoriesCompleted";
import CategoriesCreatedChart from "./categoriesCreated";
import CompletedByTech from './completedByTech';
import Priority from './priority';

const DashboardCharts = ({
  dates, properties, windowProperties, setModalData,
}) => (
  <>
    <Row>
      <Completed dates={dates} properties={properties} windowProperties={windowProperties} setModalData={setModalData} />
      <OpenHistoryChart dates={dates} properties={properties} windowProperties={windowProperties} setModalData={setModalData} />
      <CategoriesCompletedChart dates={dates} properties={properties} setModalData={setModalData} />
      <CategoriesCreatedChart dates={dates} properties={properties} setModalData={setModalData} />
      <CompletedByTech dates={dates} properties={properties} />
      <Priority properties={properties} />
    </Row>
  </>
);

export default DashboardCharts;
