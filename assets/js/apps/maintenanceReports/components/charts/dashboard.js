import React, {useEffect, useState} from "react";
import {Space, DatePicker} from "antd";
import moment from "moment";
import MultiPropertySelect from "../../../../components/multiPropertySelect";
import {getCookie} from "../../../../utils/cookies";
import DashboardCharts from "./dashboardCharts";
import InfoBoxes from "./dashboardCharts/dashboardBoxes";
import colors from "../../../usageDashboard/components/colors";

const {RangePicker} = DatePicker;
const properties = window.properties.map((p, i) => ({...p, color: colors(i, 45)}));
const dateFormats = ["MM/DD/YY", "MM/DD/YYYY", "MM-DD-YY", "MM-DD-YYYY"];

function formattedDates(dates) {
  return [dates[0].format("YYYY-MM-DD"), dates[1].format("YYYY-MM-DD")];
}

function Dashboard() {
  const [dates, setDates] = useState([moment().subtract(14, "d"), moment()]);
  const [propertiesSelected, setPropertiesSelected] = useState(getCookie("multiPropertySelector"));
  const [setModalData] = useState(null);

  useEffect(() => {
    setPropertiesSelected(getCookie("multiPropertySelector"));
  }, [getCookie("multiPropertySelector")]);

  let containerClass = "d-flex flex-row w-50 border-success"

  if(properties.length <= 1) {
    containerClass = `${containerClass} invisible`
  } else {
    containerClass = `${containerClass} visible`
  }

  return (
    <Space direction="vertical" size="large" className="w-100">
      <div className={containerClass}>
        <MultiPropertySelect
          selectProps={{bordered: true}}
          className="flex-fill"
          onChange={(p) => setPropertiesSelected(p)}
          selected={propertiesSelected}
        />
      </div>
      <InfoBoxes properties={propertiesSelected} />
      <div className="d-flex justify-content-end">
        <div className="d-flex flex-row">
          <RangePicker
            allowClear={false}
            value={dates}
            bordered={true}
            format={dateFormats}
            onChange={setDates}
          />
        </div>
      </div>
      <DashboardCharts
        dates={formattedDates(dates)}
        properties={propertiesSelected}
        windowProperties={properties}
        setModalData={setModalData}
      />
    </Space>
  );
}

export default Dashboard;
