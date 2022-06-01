import React from "react";
import moment from "moment";
import {Badge, Space, Button} from "antd";
import {EyeTwoTone} from "@ant-design/icons";

const formatTimeStamp = (timestamp) => (moment.utc(timestamp).local().format("MM/DD/YY h:mmA"));

const dateTimeRenderer = (data) => (<span>{formatTimeStamp(data)}</span>);

const propertyUnitRenderer = ({property, unit}) => (
  <span>
    {property}
    {" "}
    {unit?.number ? `- ${unit.number}` : ""}
  </span>
);

const getLocation = ({unit}) => (
  unit?.number ? unit.number : ""
);

const propertyUnitSorter = () => (
  {
    sorter: (a, b) => getLocation(a).localeCompare(getLocation(b)),
    sortDirections: ["ascend", "descend"],
  }
);

const getResident = ({tenant}) => (
  tenant ? `${tenant.first_name}${tenant.last_name}` : ""
);

const residentSorter = () => (
  {
    sorter: (a, b) => getResident(a).localeCompare(getResident(b)),
    sortDirections: ["ascend", "descend"],
  }
);

const categorySorter = () => (
  {
    sorter: (a, b) => `${a.parent_category}${a.category}`.localeCompare(`${b.parent_category}${b.category}`),
    sortDirections: ["ascend", "descend"],
  }
);

const multiStringRenderer = (field, fieldb) => (<span>{field} - {fieldb}</span>);

const residentRenderer = (data) => (
  data
    ? (
      <span>
        <a href={`https://administration.apprent.com/tenants/${data.id}`}>{data.first_name} {data.last_name}</a>
      </span>
    ) : null
);

const sortableDateColumn = (field) => (
  {
    sorter: (a, b) => (new Date(moment(a[field]))).getTime() - (new Date(moment(b[field]))).getTime(),
    sortDirections: ["ascend", "descend"],
  }
);

const sortableStringColumn = (field) => (
  {
    sorter: (a, b) => a[field] - b[field],
    sortDirections: ["ascend", "descend"],
  }
);

const CreateOrderButton = ({newOrderDrawer}) => (
  <Button onClick={() => newOrderDrawer(true)}>New Work Order</Button>
);

const uniqueAssignments = (asgns) => (
  Array.from(new Set(asgns.map((a) => a.id))).map((id) => asgns.find((a) => a.id === id))
);

const getTotalNumber = ({notes_count, assignments}) => {
  const asgns = assignments ? uniqueAssignments(assignments.filter((a) => a.tech_comments)) : [];
  return notes_count + asgns.length;
};

const notesRenderer = (order) => (
  <Badge count={getTotalNumber(order)}>
    <i className="far fa-comments text-success cursor-pointer" style={{fontSize: 32}} />
  </Badge>
);

const unassignedActionRenderer = (order) => (
  <Space size="small">
    <a
      href={`${window.url}/${order.type === "Maintenance" ? "orders" : "vendor_orders"}/${order.id}`}
      target="_blank"
      className="ml-2"
      rel="noopener noreferrer"
    >
      <EyeTwoTone style={{fontSize: 32}} twoToneColor="#1a732f" />
    </a>
  </Space>
);

const viewRendererForExport = (order) => (
  <a
    href={`${window.url}/${order.type === "Maintenance" ? "orders" : "vendor_orders"}/${order.id}`}
    target="_blank"
    rel="noopener noreferrer"
    className="ml-2"
  >
    View
  </a>
);

export {
  dateTimeRenderer,
  propertyUnitRenderer,
  sortableDateColumn,
  sortableStringColumn,
  residentRenderer,
  multiStringRenderer,
  notesRenderer,
  unassignedActionRenderer,
  CreateOrderButton,
  propertyUnitSorter,
  residentSorter,
  categorySorter,
  viewRendererForExport,
  formatTimeStamp,
};
