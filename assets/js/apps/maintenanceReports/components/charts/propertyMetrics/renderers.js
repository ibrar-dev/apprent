import React from 'react';
import {Col, Card, Space, Avatar, Table} from 'antd';
import moment from 'moment';
import colors from '../../../../usageDashboard/components/colors';

function avatarToDisplay(property) {
  if (property.icon) return <Avatar src={property.icon} />
  return <Avatar>{property.name.split(' ').map(n => n[0]).join('').toUpperCase()}</Avatar>
}

function displayCompletionTime(amount, display) {
  switch (display) {
    case 'days':
      return moment.duration(amount, 'seconds').asDays().toFixed(2);
      break;
    case 'hours':
      return moment.duration(amount, 'seconds').asHours().toFixed(2);
      break;
    case 'weeks':
      return moment.duration(amount, 'seconds').asWeeks().toFixed(2);
      break;
    default:
      return moment.duration(amount, 'seconds').humanize();
      break;
  }
}

function coolView(data, display) {
  const col = colors(data.property.id, 75);
  return <Col span={8} key={data.property.id}>
    <Card style={{backgroundColor: col.replace(/, .*\)/, ',0.5)'), borderColor: col}}>
      <Space size={"large"} className={"d-flex flex-row justify-content-between"}>
        <Space direction={"vertical"} className="d-flex flex-column justify-content-center align-items-center">
          {avatarToDisplay(data.property)}
          <b>{data.property.name}</b>
        </Space>
        <Space direction={"vertical"} style={{textAlign: 'right'}}>
          <span><small>Made Ready:</small> {data.make_ready_units.length}</span>
          <span><small>Avg Completion Time:</small> {data.completion_time ? displayCompletionTime(data.completion_time, display) : 'N/A'} {display !== 'humanize' ? display : ''}</span>
          <span><small>Not Ready Units:</small> {data.not_ready_units.length}</span>
          <span><small>Not Yet Walked:</small> {data.not_inspected_units.length}</span>
          <span><small>Open Work Orders:</small> {data.open_orders ? data.open_orders : '0'}</span>
          <span><small>Callback Count:</small> {data.callback_count }</span>
        </Space>
      </Space>
    </Card>
  </Col>
}

function propertyDisplay(data) {
  return <Space size={"small"}>
    {avatarToDisplay(data.property)}
    {data.property.name}
  </Space>
}

function lengthDisplay(data, type) {
  return data[type].length
}

function displayCompletion(p, display) {
  if (p.completion_time) return <span>{displayCompletionTime(p.completion_time, display)} {display !== 'humanize' ? display : ''}</span>
  return "0"
}

const arraySorter = (type) => {
  return {
		sorter: (a, b) => a[type].length - b[type].length,
		sortDirections: ['ascend', 'descend']
	}
}

const staticSorter = (type) => {
  return {
		sorter: (a, b) => a[type] - b[type],
		sortDirections: ['ascend', 'descend']
	}
}

function exTableView(properties, display) {
  const columns = ["", "Made Ready", "Avg Completion Time", "Not Ready Units", "Not Yet Walked", "Open Work Orders", "Callback Count"]
  return <table className="table">
    <thead>
      <tr className="text-left bg-success text-white">
        {columns.map(c => <th key={c}>{c}</th>)}
      </tr>
    </thead>
    <tbody>
    {properties.map((p, i) => {
      return <tr key={i} className={"text-right"}>
        <td>{propertyDisplay(p)}</td>
        <td>{lengthDisplay(p, 'make_ready_units')}</td>
        <td>{displayCompletion(p, display)}</td>
        <td>{lengthDisplay(p, 'not_ready_units')}</td>
        <td>{lengthDisplay(p, 'not_inspected_units')}</td>
        <td>{p.open_orders || 0}</td>
        <td>{p.callback_count}</td>
      </tr>
    })}
    </tbody>
  </table>
}

function tableView(properties, display) {
  const columns = [
    {title: "", render: p => (propertyDisplay(p))},
    {title: "Made Ready", render: p => (lengthDisplay(p, 'make_ready_units')), ...arraySorter('make_ready_units')},
    {title: "Avg Completion Time", render: p => displayCompletion(p, display), ...staticSorter('completion_time')},
    {title: "Not Ready Units", render: p => (lengthDisplay(p, 'not_ready_units')), ...arraySorter('not_ready_units')},
    {title: "Not Yet Walked", render: p => (lengthDisplay(p, 'not_inspected_units')), ...arraySorter('not_inspected_units')},
    {title: "Open Work Orders", dataIndex: 'open_orders', ...staticSorter('open_orders')},
    {title: "Callback Count", dataIndex: "callback_count", ...staticSorter("callback_count")}
  ]

  return <Table className={"w-100"}
    pagination={{defaultPageSize: 50, showQuickJumper: true, showSizeChanger: true}}
    size={"large"}
    rowKey={p => p.property.id}
    dataSource={properties}
    columns={columns} />
}

export {
  coolView,
  tableView,
  exTableView
}
