import React, {useEffect, useState} from "react";
import {Space, DatePicker} from "antd";
import moment from "moment";
import {getCookie} from "../../../utils/cookies";
import MultiPropertySelect from "../../../components/multiPropertySelect";
import infoBoxes from "./infoBoxes";
import charts from "./charts";

const {RangePicker} = DatePicker;
const dateFormats = ["MM/DD/YY", "MM/DD/YYYY", "MM-DD-YY", "MM-DD-YYYY"];

function paymentsAnalyticsApp() {
  const [propertiesSelected, setPropertiesSelected] = useState(getCookie("multiPropertySelector"));
  const [dates, setDates] = useState([moment().subtract(2, "month").startOf("month"), moment()]);

  useEffect(() => {
    setPropertiesSelected(getCookie("multiPropertySelector"));
  }, [getCookie("multiPropertySelector")]);

  return (
    <div className="w-100 card">
      <div className="card-body">
        <Space direction="vertical" size="large" className="w-100">
          <div className="w-50">
            <MultiPropertySelect
              selectProps={{bordered: true}}
              className="flex-fill"
              onChange={(p) => setPropertiesSelected(p)}
              selected={propertiesSelected}
            />
          </div>
          {infoBoxes(propertiesSelected)}
          <div className="d-flex justify-content-end">
            <div className="d-flex flex-row">
              <RangePicker
                allowClear={false}
                value={dates}
                bordered
                format={dateFormats}
                onChange={setDates}
              />
            </div>
          </div>
          {charts(propertiesSelected, dates)}
        </Space>
      </div>
    </div>
  )
}

export default paymentsAnalyticsApp;