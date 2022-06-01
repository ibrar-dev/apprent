import React from 'react';
import {Table, Space, Skeleton} from 'antd';
import {connect} from "react-redux";
import DetailedTable from './detailedTable';
import {sortableStringColumn, totalNestedData, complexSortColumn, viewDetailedRender, getTotal, clickableCell} from "./functions";

const columns = [
  {title: "Name", dataIndex: 'name', simpleSort: true},
  {title: "Units", dataIndex: 'unit_count', simpleSort: true},
  {title: "Move In", dataIndex: 'actual_move_in', complexSortColumn: true, render: data => (viewDetailedRender(data)), onCell: r => clickableCell(r, ['actual_move_in'])},
  {title: "Move Out", dataIndex: 'actual_move_out', complexSortColumn: true, render: data => (viewDetailedRender(data)), onCell: r => clickableCell(r, ['actual_move_out'])},
  {title: "Notice Given", dataIndex: 'notice_date', complexSortColumn: true, render: data => (viewDetailedRender(data)), onCell: r => clickableCell(r, ['notice_date'])},
  {title: "Month to Month", dataIndex: 'end_date', complexSortColumn: true, render: data => (viewDetailedRender(data)), onCell: r => clickableCell(r, ['end_date'])},
  {title: "Transfer", dataIndex: 'name', render: () => (<span>N/A</span>)},
  {title: "Renewal", dataIndex: 'renewals', complexSortColumn: true, render: data => (viewDetailedRender(data)), onCell: r => clickableCell(r, ['renewals'])},
  {title: "Eviction", dataIndex: 'evictions', complexSortColumn: true, render: data => (viewDetailedRender(data)), onCell: r => clickableCell(r, ['evictions'])},
];

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

function summary(report) {
  if (!report) {
    return <Table.Summary.Row />
  }
  return (
    <Table.Summary.Row>
      <Table.Summary.Cell><b>Total</b></Table.Summary.Cell>
      <Table.Summary.Cell><b>{getTotal(report, 'unit_count')}</b></Table.Summary.Cell>
      <Table.Summary.Cell><b>{totalNestedData(report, ['actual_move_in', 'count'])}</b></Table.Summary.Cell>
      <Table.Summary.Cell><b>{totalNestedData(report, ['actual_move_out', 'count'])}</b></Table.Summary.Cell>
      <Table.Summary.Cell><b>{totalNestedData(report, ['notice_date', 'count'])}</b></Table.Summary.Cell>
      <Table.Summary.Cell><b>{totalNestedData(report, ['end_date', 'count'])}</b></Table.Summary.Cell>
      <Table.Summary.Cell><b>N/A</b></Table.Summary.Cell>
      <Table.Summary.Cell><b>{totalNestedData(report, ['renewals', 'count'])}</b></Table.Summary.Cell>
      <Table.Summary.Cell><b>{totalNestedData(report, ['evictions', 'count'])}</b></Table.Summary.Cell>
    </Table.Summary.Row>
  )
}

function ResidentActivityReport({reportData, skeleton, detailed, dates}) {
  if (skeleton || reportData.floor_plans) {
    return <Skeleton active={true} paragraph={{paragraph: 10, width: '100%'}} />
  }
  return (
    <div className={"w-100"}>
      <Space className={"w-100"} size={"large"} direction={"vertical"}>
        <Table className={"w-100"}
               dataSource={reportData}
               rowKey={fp => fp.id}
               pagination={false}
               bordered
               summary={data => summary(data)}
               title={() => `Resident Activity from ${dates[0].format("MM/DD/YY")} - ${dates[1].format("MM/DD/YY")}`}
               size={"middle"}
               columns={mergedColumns()}/>
        {detailed && <DetailedTable />}
      </Space>
    </div>
  )
}

export default connect(({reportData, skeleton, detailed}) => {
  return {reportData, skeleton, detailed}
})(ResidentActivityReport)