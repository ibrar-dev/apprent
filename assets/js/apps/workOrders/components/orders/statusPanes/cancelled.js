import React from "react";
import {Space, Table} from "antd";
import moment from "moment";
import {
  CreateOrderButton,
  cancelledAdmin,
  cancelledAdminSorter,
  cancelledAdminString,
  cancelledOnRender,
  cancelledOnSorter,
  cancelledOnString,
  cancelledReason,
  cancelledReasonSorter,
  cancelledReasonString,
  clickableCell,
  dateTimeRenderer,
  formatTimeStamp,
  multiStringRenderer,
  notesRenderer,
  sortableDateColumn,
  submittedOnRender,
  unassignedActionRenderer,
  unitRender,
  unitSorter,
  viewRendererForExport,
} from "../renderers";
import PdfExport from "../../../../../components/pdf";
import CsvExport from "../exports/csv";

const columns = [
  {title: "Submitted On", render: (o) => submittedOnRender(o), ...sortableDateColumn("inserted_at")},
  {title: "Cancelled On", render: (o) => cancelledOnRender(o), ...cancelledOnSorter()},
  {title: "Unit #", render: (o) => unitRender(o), ...unitSorter()},
  {title: "Reason", render: (o) => cancelledReason(o), ...cancelledReasonSorter()},
  {title: "Cancelled By", render: (o) => cancelledAdmin(o), ...cancelledAdminSorter()},
  {title: "Notes", render: (o) => notesRenderer(o), onCell: (r) => clickableCell(r)},
  {title: "", render: (o) => unassignedActionRenderer(o)},
];

const exportColumns = ["Submitted Date", "Cancelled On", "Unit #", "Reason", "Cancelled By", "Category", "View"];
const exportRows = (orders) => orders.map((o) => [
  dateTimeRenderer(o.inserted_at),
  cancelledOnRender(o),
  unitRender(o),
  cancelledReason(o),
  cancelledAdmin(o),
  multiStringRenderer(o.parent_category, o.category),
  viewRendererForExport(o),
]);
const exportFileName = (dates) => `Cancelled_${moment(dates[0]).format("MMDDYY")}-${moment(dates[1]).format("MMDDYY")}`;

const csvData = (orders) => (
  [["Submitted", "Cancelled On", "Unit", "Reason", "Cancelled By"]].concat(
    orders.map((order) => [
      formatTimeStamp(order.inserted_at),
      cancelledOnString(order),
      order?.unit?.number || "",
      cancelledReasonString(order),
      cancelledAdminString(order),
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

const CancelledOrders = ({orders, newOrderDrawer, dates}) => {
  return(
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
  )
}

export default CancelledOrders;
