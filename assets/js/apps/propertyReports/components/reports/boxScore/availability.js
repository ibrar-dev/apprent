import React from 'react';
import {Table, Space, Skeleton} from 'antd';
import {connect} from "react-redux";
import actions from '../../../actions';
import {titleize} from "../../../../../utils";
import DetailedTable from './detailedTable';
import {sortableStringColumn, complexSortColumn, numberRenderer, percentageRenderer, viewDetailedRender, getTotal, avgData, totalNestedData} from "./functions";

const columns = [
  {title: "Name", ellipses: true, dataIndex: 'name', simpleSort: true},
  {title: "Avg Sq Feet", ellipses: true, dataIndex: 'avg_sq_ft', render: num => (numberRenderer(num)), simpleSort: true},
  {title: "Avg Rent", ellipses: true, dataIndex: 'avg_rent', render: num => (numberRenderer(num)), simpleSort: true},
  {title: "Units", ellipses: true, dataIndex: 'unit_count', simpleSort: true},
  {title: "Occupied", ellipses: true, dataIndex: ['units', 'occupied'], render: data => (viewDetailedRender(data)), onCell: r => clickableCell(r, ['units', 'occupied']), complexSortColumn: true},
  {title: "Vacant Rented", ellipses: true, dataIndex: ['units', 'vacant_rented'], render: data => (viewDetailedRender(data)), onCell: r => clickableCell(r, ['units', 'vacant_rented']), complexSortColumn: true},
  {title: "Vacant Unrented", ellipses: true, dataIndex: ['units', 'vacant_unrented'], render: data => (viewDetailedRender(data)), onCell: r => clickableCell(r, ['units', 'vacant_unrented']), complexSortColumn: true},
  {title: "Notice Rented", ellipses: true, dataIndex: ['units', 'notice_rented'], render: data => (viewDetailedRender(data)), onCell: r => clickableCell(r, ['units', 'notice_rented']), complexSortColumn: true},
  {title: "Notice Unrented", ellipses: true, dataIndex: ['units', 'notice_unrented'], render: data => (viewDetailedRender(data)), onCell: r => clickableCell(r, ['units', 'notice_unrented']), complexSortColumn: true},
  {title: "Available", ellipses: true, dataIndex: ['units', 'available'], render: data => (viewDetailedRender(data)), onCell: r => clickableCell(r, ['units', 'available']), complexSortColumn: true},
  {title: "Model", ellipses: true, dataIndex: ['units', 'model'], render: data => (viewDetailedRender(data)), onCell: r => clickableCell(r, ['units', 'model']), complexSortColumn: true},
  {title: "Down", ellipses: true, dataIndex: ['units', 'down'], render: data => (viewDetailedRender(data)), onCell: r => clickableCell(r, ['units', 'down']), complexSortColumn: true},
  {title: "Occupancy", ellipses: true, dataIndex: ['calculations', 'occ'], render: num => (percentageRenderer(num)), complexSortColumn: true},
  {title: "W/ Non-Rev", ellipses: true, dataIndex: ['calculations', 'occ_non_rev'], render: num => (percentageRenderer(num)), complexSortColumn: true},
  {title: "Leased", ellipses: true, dataIndex: ['calculations', 'leased'], render: num => (percentageRenderer(num)), complexSortColumn: true},
  {title: "Trend", ellipses: true, dataIndex: ['calculations', 'trend'], render: num => (percentageRenderer(num)), complexSortColumn: true},
];

function clickableCell(record, pathToData) {
  const data = {
    title: `Detailed ${titleize(pathToData[pathToData.length - 1])} for ${record.name}`,
    data: pathToData.reduce((acc, f) => (acc[f]), record)
  };
  return {
    onClick: () => actions.setDetailedData(data),
  }
}

function mergedColumns() {
  return columns.map(c => {
    if (c.simpleSort) {
      return {...c, ...sortableStringColumn(c.dataIndex)}
    } else if (c.complexSortColumn) {
      return {...c, ...complexSortColumn(c.dataIndex)}
    } else {
      return c
    }
  })
}

function summary(report, property_calculations) {
  if (!property_calculations) {
    return <Table.Summary.Row />
  }
  return (
    <Table.Summary.Row>
      <Table.Summary.Cell><b>Total</b></Table.Summary.Cell>
      <Table.Summary.Cell><b>{avgData(report, 'avg_sq_ft')}</b></Table.Summary.Cell>
      <Table.Summary.Cell><b>{avgData(report, 'avg_rent')}</b></Table.Summary.Cell>
      <Table.Summary.Cell><b>{getTotal(report, 'unit_count')}</b></Table.Summary.Cell>
      <Table.Summary.Cell><b>{totalNestedData(report, ['units', 'occupied', 'count'])}</b></Table.Summary.Cell>
      <Table.Summary.Cell><b>{totalNestedData(report, ['units', 'vacant_rented', 'count'])}</b></Table.Summary.Cell>
      <Table.Summary.Cell><b>{totalNestedData(report, ['units', 'vacant_unrented', 'count'])}</b></Table.Summary.Cell>
      <Table.Summary.Cell><b>{totalNestedData(report, ['units', 'notice_rented', 'count'])}</b></Table.Summary.Cell>
      <Table.Summary.Cell><b>{totalNestedData(report, ['units', 'notice_unrented', 'count'])}</b></Table.Summary.Cell>
      <Table.Summary.Cell><b>{totalNestedData(report, ['units', 'available', 'count'])}</b></Table.Summary.Cell>
      <Table.Summary.Cell><b>{totalNestedData(report, ['units', 'model', 'count'])}</b></Table.Summary.Cell>
      <Table.Summary.Cell><b>{totalNestedData(report, ['units', 'down', 'count'])}</b></Table.Summary.Cell>
      <Table.Summary.Cell><b>{property_calculations.occ || ''}%</b></Table.Summary.Cell>
      <Table.Summary.Cell><b>{property_calculations.occ_non_rev || ''}%</b></Table.Summary.Cell>
      <Table.Summary.Cell><b>{property_calculations.leased || ''}%</b></Table.Summary.Cell>
      <Table.Summary.Cell><b>{property_calculations.trend || ''}%</b></Table.Summary.Cell>
    </Table.Summary.Row>
  )
}

function AvailabilityReport({reportData, skeleton, detailed, dates}) {
  if (skeleton) {
    return <Skeleton active={true} paragraph={{paragraph: 10, width: '100%'}} />
  }

  const {floor_plans, property_calculations} = reportData;

  return (
    <div className="w-100">
      <Space className={"w-100"} size={"large"} direction={"vertical"}>
        <Table className={"w-100"}
               dataSource={floor_plans}
               size={"middle"}
               rowKey={fp => fp.id}
               pagination={false}
               bordered
               title={() => `Availability as of ${dates[1].format("MM/DD/YY")}`}
               summary={data => summary(data, property_calculations)}
               columns={mergedColumns()} />
        {detailed && <DetailedTable />}
      </Space>
    </div>
  )
}

export default connect(({reportData, skeleton, detailed}) => {
  return {reportData, skeleton, detailed}
})(AvailabilityReport)