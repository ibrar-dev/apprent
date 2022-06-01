import React from "react";
import {connect} from "react-redux";
import {Skeleton, Table, Space} from "antd";
import moment from "moment";
import {
  CreateOrderButton,
  multiStringRenderer,
  categorySorter,
  completedDateSorter,
  ratingSorter,
  notesRenderer,
  propertyUnitRenderer,
  clickableCell,
  propertyUnitSorter,
  assignedToSorter,
  assignedToRenderer,
  ratingRender,
  completedAtRender,
  timeOpen,
  unassignedActionRenderer,
  viewRendererForExport,
  daysIncompleteSorter,
  completedAtString,
  timeOpenString,
  getAssignedTo,
} from "../renderers";
import PdfExport from "../../../../../components/pdf";
import CsvExport from "../exports/csv";

const columns = [
  {title: "Completion Date", render: (o) => (completedAtRender(o)), ...completedDateSorter()},
  {title: "Days Incomplete", render: (o) => (timeOpen(o)), ...daysIncompleteSorter()},
  {title: "Location", render: (o) => (propertyUnitRenderer(o)), ...propertyUnitSorter()},
  {title: "Completed By", render: (o) => (assignedToRenderer(o)), ...assignedToSorter()},
  {title: "Category", render: (o) => (multiStringRenderer(o.parent_category, o.category)), ...categorySorter()},
  {title: "Rating", render: (o) => (ratingRender(o.assignments)), ...ratingSorter()},
  {title: "Notes", render: (o) => (notesRenderer(o)), onCell: (r) => clickableCell(r)},
  {title: "", render: (o) => unassignedActionRenderer(o)},
];

const exportColumns = ["Completion Date", "Days Incomplete", "Location", "Completed By", "Category", "View"];
const exportRows = (orders) => orders.map((o) => [
  completedAtRender(o),
  timeOpen(o),
  propertyUnitRenderer(o),
  assignedToRenderer(o),
  multiStringRenderer(o.parent_category, o.category),
  viewRendererForExport(o),
]);
const exportFileName = (dates) => (
  `Completed_${moment(dates[0]).format("MMDDYY")}-${moment(dates[1]).format("MMDDYY")}`
);

const csvData = (orders) => (
  [["Completion Date", "Days Incomplete", "Location", "Completed By", "Category", "Rating"]].concat(
    orders.map((order) => [
      completedAtString(order),
      timeOpenString(order),
      `${order.property} - ${order.unit.number}`,
      getAssignedTo(order),
      multiStringRenderer(order.parent_category, order.category),
      order.rating,
    ]),
  )
);

const actionButtons = (newOrderDrawer, orders, dates) => (
  <div className="d-flex justify-content-between">
    <div />
    <Space size="small">
      <CreateOrderButton newOrderDrawer={newOrderDrawer} />
      <PdfExport
        rows={exportRows(orders)}
        columns={exportColumns}
        fileName={exportFileName(dates)}
      />
      <CsvExport fileName={exportFileName(dates)} data={csvData(orders)} />
    </Space>
  </div>
);

const CompletedOrders = ({orders, skeleton, newOrderDrawer, dates}) => {
  if (skeleton) return <Skeleton active paragraph={{paragraph: 10, width: "100%"}} />;

  return (
    <>
      <Table
        className="w-100"
        rowKey={(o) => `${o.type}-${o.id}`}
        pagination={{defaultPageSize: 50, showQuickJumper: true, showSizeChanger: true}}
        size="small"
        columns={columns}
        title={() => actionButtons(newOrderDrawer, orders, dates)}
        dataSource={orders}
      />
    </>
  );
};

export default connect(({skeleton}) => ({skeleton}))(CompletedOrders);
