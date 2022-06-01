import React, {useState} from "react";
import {Skeleton, Table} from "antd";
import {connect} from "react-redux";
import moment from "moment";
import canEdit from "../../../../../components/canEdit";
import {
  assignedToRenderer,
  assignedAtTimeString,
  notesRenderer,
  residentRenderer,
  assignedToSorter,
  multiStringRenderer,
  propertyUnitRenderer,
  assignedAtRenderer,
  assignedAtSorter,
  unassignedActionRenderer,
  clickableCell,
  priorityRowRender,
  submittedOnRender,
  propertyUnitSorter,
  residentSorter,
  categorySorter,
  dateTimeRenderer,
  viewRendererForExport,
  sortableDateColumn,
  formatTimeStamp,
  getAssignedTo,
} from "../renderers";
import actions from "../../../actions";
import ActionButtons from "./assigned/actionButtons";

const columns = [
  {title: "Submitted", render: (o) => (submittedOnRender(o)), ...sortableDateColumn("inserted_at")},
  {title: "Assigned On", render: (o) => (assignedAtRenderer(o)), ...assignedAtSorter()},
  {title: "Assigned To", render: (o) => (assignedToRenderer(o)), ...assignedToSorter()},
  {title: "Location", render: (o) => (propertyUnitRenderer(o)), ...propertyUnitSorter()},
  {title: "Resident", dataIndex: "tenant", render: (o) => (residentRenderer(o)), ...residentSorter()},
  {title: "Category", render: (o) => (multiStringRenderer(o.parent_category, o.category)), ...categorySorter()},
  {title: "Notes/Comments", render: (o) => (notesRenderer(o)), onCell: (r) => clickableCell(r)},
  {title: "", render: (o) => unassignedActionRenderer(o)},
];

const exportRows = (orders) => orders.map((o) => [
  dateTimeRenderer(o.inserted_at),
  assignedAtRenderer(o),
  assignedToRenderer(o),
  propertyUnitRenderer(o),
  residentRenderer(o.tenant),
  multiStringRenderer(o.parent_category, o.category),
  viewRendererForExport(o),
]);
const exportFileName = (dates) => `Assigned_${moment(dates[0]).format("MMDDYY")}-${moment(dates[1]).format("MMDDYY")}`;

const csvData = (orders) => (
  [["Submitted", "Assigned On", "Assigned To", "Location", "Resident", "Category"]].concat(
    orders.map((order) => [
      formatTimeStamp(order.inserted_at),
      assignedAtTimeString(order),
      getAssignedTo(order),
      `${order.property} - ${order.unit.number}`,
      order.tenant ? `${order.tenant.first_name} - ${order.tenant.last_name}` : "N/A",
      multiStringRenderer(order.parent_category, order.category),
    ]),
  )
);

const rowSelection = (setSelected) => ({
  onChange: (_selectedRowKeys, selectedRows) => setSelected(selectedRows),
  type: "checkbox",
  getCheckboxProps: (o) => ({disabled: !canEdit(["Super Admin", "Admin", "Regional", "Tech"]) || o.type === "Vendor"}),
});

const AssignedOrders = ({orders, skeleton, newOrderDrawer, dates}) => {
  const [selected, setSelected] = useState([]);

  const onRevoke = () => {
    const assignment_ids = selected.map((o) => o.assignments[0].id);
    actions.revokeAssignments(assignment_ids);
  };

  if (skeleton) return <Skeleton active paragraph={{paragraph: 10, width: "100%"}} />;

  return (
    <Table
      className="w-100"
      onRow={(order) => priorityRowRender(order)}
      rowKey={(o) => `${o.type}-${o.id}`}
      pagination={{defaultPageSize: 50, showQuickJumper: true, showSizeChanger: true}}
      size="small"
      columns={columns}
      title={() => (
        <ActionButtons
          onRevoke={onRevoke}
          length={selected.length}
          newOrderDrawer={newOrderDrawer}
          orders={orders}
          dates={dates}
          exportRows={exportRows}
          exportFileName={exportFileName}
          csvData={csvData}
        />
      )}
      rowSelection={rowSelection(setSelected)}
      dataSource={orders}
    />
  );
};

export default connect(({skeleton}) => ({skeleton}))(AssignedOrders);
