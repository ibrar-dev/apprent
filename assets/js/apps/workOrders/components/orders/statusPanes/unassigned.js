import React, {useState} from "react";
import {Skeleton, Table, Space, Button} from "antd";
import {MobileTwoTone, CarTwoTone} from "@ant-design/icons";
import {connect} from "react-redux";
import moment from "moment";
import {
  dateTimeRenderer,
  propertyUnitRenderer,
  sortableDateColumn,
  sortableStringColumn,
  residentRenderer,
  multiStringRenderer,
  notesRenderer,
  unassignedActionRenderer,
  CreateOrderButton,
  priorityRowRender,
  propertyUnitSorter,
  residentSorter,
  categorySorter,
  viewRendererForExport,
  formatTimeStamp,
} from "../renderers";
import actions from "../../../actions";
import canEdit from "../../../../../components/canEdit";
import AssignDrawer from "../assignDrawer";
import OutsourceDrawer from "../outsourceDrawer";
import PdfExport from "../../../../../components/pdf";
import CsvExport from "../exports/csv";

const columns = [
  {title: "Submitted On", dataIndex: "inserted_at", render: (o) => (dateTimeRenderer(o)), ...sortableDateColumn("inserted_at"), showSorterTooltip: false},
  {title: "Location", render: (o) => (propertyUnitRenderer(o)), ...propertyUnitSorter()},
  {title: "Resident", dataIndex: "tenant", render: (o) => (residentRenderer(o)), ...residentSorter()},
  {title: "Category", render: (o) => (multiStringRenderer(o.parent_category, o.category)), ...categorySorter()},
  {title: "Notes/Comments", render: (o) => notesRenderer(o), onCell: (r) => clickableCell(r)},
  {title: "Ticket", dataIndex: "ticket"},
  {title: "", render: (o) => unassignedActionRenderer(o)},
];

const exportColumns = ["Submitted", "Location", "Resident", "Category", "Ticket", "View"];
const exportRows = (orders) => (
  orders.map((o) => [
    dateTimeRenderer(o.inserted_at),
    propertyUnitRenderer(o),
    residentRenderer(o.tenant),
    multiStringRenderer(o.parent_category, o.category),
    o.ticket,
    viewRendererForExport(o),
  ])
);

const exportFileName = (dates) => (
  `Unassigned_${moment(dates[0]).format("MMDDYY")}-${moment(dates[1]).format("MMDDYY")}`
);

const mergedColumns = () => (
  columns.map((c) => {
    if (c.simpleSort) return {...c, ...sortableStringColumn(c.dataIndex)};
    if (c.dateSort) return {...c, ...sortableDateColumn(c.dataIndex)};
    return c;
  })
);

const clickableCell = (record) => ({onClick: () => actions.setOrderData(record)});

const rowSelection = (setSelected) => (
  {
    onChange: (_selectedRowKeys, selectedRows) => { setSelected(selectedRows); },
    type: "checkbox",
    getCheckboxProps: () => ({disabled: !canEdit(["Super Admin", "Admin", "Regional", "Tech"])}),
  }
);

const csvData = (orders) => (
  [["Submitted", "Location", "Resident", "Category"]].concat(
    orders.map((order) => [
      formatTimeStamp(order.inserted_at),
      `${order.property} - ${order.unit.number}`,
      order.tenant ? `${order.tenant.first_name} - ${order.tenant.last_name}` : "N/A",
      multiStringRenderer(order.parent_category, order.category),
    ]),
  )
);

const actionButtons = (setAction, length, newOrderDrawer, orders, dates) => (
  <div className="d-flex justify-content-between">
    <Space size="small">
      <Button
        disabled={length < 1}
        onClick={() => setAction("assign")}
        type="link"
        icon={<MobileTwoTone />}
      >
        Assign
      </Button>
      <Button
        disabled={length < 1}
        onClick={() => setAction("outsource")}
        type="link"
        icon={<CarTwoTone />}
      >
        Outsource
      </Button>
    </Space>
    <Space size="small">
      <CreateOrderButton newOrderDrawer={newOrderDrawer} />
      <PdfExport
        rows={exportRows(orders)}
        columns={exportColumns}
        fileName={exportFileName(dates)}
      />
      <CsvExport
        fileName={exportFileName(dates)}
        data={csvData(orders)}
      />
    </Space>
  </div>
);

const closeAndClear = (setAction, setSelected) => {
  setAction("");
  setSelected([]);
};

const UnassignedOrders = ({orders, skeleton, newOrderDrawer, dates}) => {
  const [selected, setSelected] = useState([]);
  const [action, setAction] = useState("");

  if (skeleton) return <Skeleton active paragraph={{paragraph: 10, width: "100%"}} />;

  return (
    <>
      <Table
        className="w-100"
        onRow={(order) => priorityRowRender(order)}
        rowKey={(o) => `${o.type}-${o.id}`}
        pagination={{defaultPageSize: 50, showQuickJumper: true, showSizeChanger: true}}
        columns={mergedColumns()}
        size="small"
        title={() => actionButtons(setAction, selected.length, newOrderDrawer, orders, dates)}
        rowSelection={rowSelection(setSelected)}
        dataSource={orders}
        locale={{emptyText: "Hooray! No unassigned work orders."}}
      />
      {action === "assign" && (
        <AssignDrawer
          close={() => setAction("")}
          visible={action === "assign"}
          selected={selected}
          closeAndClear={() => closeAndClear(setAction, setSelected)}
        />
      )}
      {action === "outsource" && (
        <OutsourceDrawer
          close={() => setAction("")}
          visible={action === "outsource"}
          selected={selected}
          closeAndClear={() => closeAndClear(setAction, setSelected)}
        />
      )}
    </>
  );
};

export default connect(({skeleton}) => ({skeleton}))(UnassignedOrders);
