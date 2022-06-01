import React, {useState, useEffect} from "react";
import moment from "moment";
import {Row, Col, Space, Button, DatePicker, Tooltip} from "antd";
import {AvailabilityReport, ResidentActivityReport, FirstContactReport} from "./reports";
import actions from "../../../actions";

const {RangePicker} = DatePicker;

const dateFormats = ["MM/DD/YY", "MM/DD/YYYY", "MM-DD-YY", "MM-DD-YYYY"];

function formatDatesForFetch([startDate, endDate]) {
  return [startDate.format("YYYY-MM-DD"), endDate.format("YYYY-MM-DD")];
}

function BoxScoreReport() {
  const [report, setReport] = useState("availability");
  const [dates, setDates] = useState([moment().startOf("month"), moment()]);

  useEffect(() => {
    if (dates) {
      actions.fetchBoxScore(report, formatDatesForFetch(dates));
    }
  }, [report, dates]);

  function handleReport(report) {
    actions.clearReportData().then(() => {
      setReport(report);
    });
  }

  return (
    <Row justify={"center"}>
      <Col span={24}>
        <Row justify={"center"} gutter={[8, 40]}>
          <Col span={24} align={"middle"}>
            <Space align="center" size="small">
              <Tooltip placement={"topLeft"} title={"Information will be shown based on End Date"}>
                <Button type={report === "availability" ? "primary" : ""} onClick={() => handleReport("availability")}>
                  Availability
                </Button>
              </Tooltip>
              <Button type={report === "residentActivity" ? "primary" : ""} onClick={() => handleReport("residentActivity")}>
                Resident Activity
              </Button>
              <Button type={report === "firstContact" ? "primary" : ""} onClick={() => handleReport("firstContact")}>
                Applicants
              </Button>
              <RangePicker
                value={dates}
                format={dateFormats}
                onChange={setDates}
              />
              <Button
                className='m-0 ml-2'
                color='dark'
                outline size='sm'
                onClick={() => window.print()}
              >
                <i className={"far fa-file-pdf"} />
              </Button>
            </Space>
          </Col>
        </Row>
        <Row justify={"start"} gutter={[8, 40]}>
          {report === "availability" && <AvailabilityReport dates={dates} />}
          {report === "residentActivity" && <ResidentActivityReport dates={dates} />}
          {report === "firstContact" && <FirstContactReport dates={dates} />}
        </Row>
      </Col>
    </Row>
  );
}

export default BoxScoreReport;
