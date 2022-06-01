import React, {useEffect, useState} from "react";
import {Space, DatePicker} from "antd";
import moment from "moment";
import axios from "axios";
import {getCookie} from "../../../utils/cookies";
import MultiPropertySelect from "../../../components/multiPropertySelect";
import InfoBoxes from "./infoBoxes";
import StaticCharts from "./staticCharts";
import DateCharts from "./dateCharts";

const {RangePicker} = DatePicker;
const dateFormats = ["MM/DD/YY", "MM/DD/YYYY", "MM-DD-YY", "MM-DD-YYYY"];

function formattedDates(dates) {
  return [dates[0].format("YYYY-MM-DD"), dates[1].format("YYYY-MM-DD")];
}

const ApprovalsAnalyticsApp = () => {
  const [propertiesSelected, setPropertiesSelected] = useState(getCookie("multiPropertySelector"));
  const [dates, setDates] = useState([moment().subtract(5, "month").startOf("month"), moment()]);
  const [data, setData] = useState([]);
  const [fetching, setFetching] = useState(false);

  useEffect(() => {
    setPropertiesSelected(getCookie("multiPropertySelector"));
  }, [getCookie("multiPropertySelector")]);

  useEffect(() => {
    if (propertiesSelected && propertiesSelected.length) {
      const fetchData = async () => {
        setFetching(true);
        const result = await axios(`/api/approvals_analytics?chart&properties=${propertiesSelected}&dates=${formattedDates(dates)}`);
        setData(result.data);
        setFetching(false);
      };
      fetchData();
    }
  }, [propertiesSelected, dates]);

  return (
    <div className="w-100 card">
      <div className="card-header" />
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
          <InfoBoxes properties={propertiesSelected} />
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
          <StaticCharts
            data={data}
            dates={dates}
            fetching={fetching}
          />
          <DateCharts
            data={data}
            fetching={fetching}
          />
        </Space>
      </div>
    </div>
  );
};

export default ApprovalsAnalyticsApp;
