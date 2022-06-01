import React, {useEffect, useState} from 'react';
import ReactDOMServer from 'react-dom/server'
import {connect} from "react-redux";
import moment from 'moment';
import {Row, Col, DatePicker, Radio, Card, Space, Avatar} from 'antd';
import actions from '../../../actions';
import colors from '../../../../usageDashboard/components/colors';
import {coolView, tableView, exTableView} from './renderers.js';
import iconButton from '../pdfExport';

const {RangePicker} = DatePicker;

const dateFormats = ['MM/DD/YY', 'MM/DD/YYYY', 'MM-DD-YY', 'MM-DD-YYYY'];

function formattedDates(dates) {
  return [dates[0].format("YYYY-MM-DD"), dates[1].format("YYYY-MM-DD")]
}

function avatarToDisplay(property) {
  if (property.icon) return <Avatar src={property.icon} />
  return <Avatar>{property.name.split(' ').map(n => n[0]).join('').toUpperCase()}</Avatar>
}

function displayCompletionTime(amount, display) {
  switch (display) {
    case 'days':
      return moment.duration(amount, 'seconds').asDays().toFixed(1)
      break;
    case 'hours':
      return moment.duration(amount, 'seconds').asHours().toFixed(1);
      break;
    case 'weeks':
      return moment.duration(amount, 'seconds').asWeeks().toFixed(1);
      break;
    default:
      return moment.duration(amount, 'seconds').humanize();
      break;
  }
}

function displayProperty(data, boringView, display) {
  return coolView(data, boringView, display);
}

const propertiesToDisplay = (properties, suppressZeros) => {
  return properties.filter(p => {
    if (suppressZeros && p.units.length <= 0 &&
      p.made_ready_units.length <= 0 &&
      p.not_inspected_units.length <= 0 &&
      !p.open_orders && !p.completion_time) return;
    return p;
  })
}

function exable(reportData, boringView, display) {
  return ReactDOMServer.renderToString(exTableView(propertiesToDisplay(reportData), display))
}

function PropertyMetrics({reportData}) {
  const [boringView, setBoringView] = useState(false);
  const [suppressZeros, setSuppressZeros] = useState(false);
  const [display, setDisplay] = useState('humanize');
  const [openProperty, setOpenProperty] = useState(null);
  const [dates, setDates] = useState([moment().subtract(14, 'd'), moment()]);

  useEffect(() => {
    if (reportData && !reportData.length) {
      actions.fetchDatedReport(
        "property_metrics",
        moment().startOf('month').format("YYYY-MM-DD"),
        moment().format("YYYY-MM-DD"))
    }
  }, [])

  useEffect(() => {
    const formatted = formattedDates(dates);
    actions.fetchDatedReport(
      "property_metrics",
      formatted[0],
      formatted[1]
    )
  }, [dates]);

  return <Row>
    <Col span={24}>
      <Row className={"d-flex align-items-center"}>
        <Col span={8}>
          <Radio.Group value={boringView} onChange={e => setBoringView(e.target.value)}>
            <Radio.Button value={false}>Cool View</Radio.Button>
            <Radio.Button value={true}>Table View</Radio.Button>
          </Radio.Group>
        </Col>
        <Col span={8} >
          <Radio.Group value={display} onChange={e => setDisplay(e.target.value)}>
            <Radio.Button value={'humanize'}>Readable</Radio.Button>
            <Radio.Button value={'hours'}>Hours</Radio.Button>
            <Radio.Button value={'days'}>Days</Radio.Button>
            <Radio.Button value={'weeks'}>weeks</Radio.Button>
          </Radio.Group>
        </Col>
        <Col span={8} className={"d-flex justify-content-end align-items-center"}>
          {iconButton(exable(reportData, display), "Property Metrics.pdf")}
          <div className="d-flex flex-row border border-secondary">
            <RangePicker
              allowClear={false}
              value={dates}
              bordered={false}
              format={dateFormats}
              onChange={setDates}
            />
          </div>
        </Col>
      </Row>
      <Row className={"mt-3"} gutter={[16, { xs: 8, sm: 16, md: 24, lg: 32 }]}>
        {reportData.length >= 1 && !boringView && propertiesToDisplay(reportData).map(p => coolView(p, display))}
        {reportData.length >= 1 && boringView && tableView(propertiesToDisplay(reportData), display)}
      </Row>
    </Col>
  </Row>
}

export default connect(({reportData}) => {
  return {reportData}
})(PropertyMetrics)
