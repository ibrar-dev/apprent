import React from 'react';
import {Space, Avatar, Tag} from 'antd';
import {titleize} from "../../../../../utils";

const priorities = {0: "Standard", 1: "Standard", 2: "Standard", 3: "Violation", 4: "Standard", 5: "Emergency"}

const windowProperty = (property_id) => {
  return window.properties.find(p => p.id === property_id)
};

function getTitle(name) {
  return name.split(' ').map(n => n[0]).join('').toUpperCase()
}

function getAvatar(p) {
  if (p.icon) return <Avatar size={"small"} src={p.icon}/>
  return <Avatar size={"small"}>{getTitle(p.name)}</Avatar>
}

function pageTitle(order) {
  const p = windowProperty(order.property_id);
  return <Space size={"small"}>
    {getAvatar(p)}
    <span>{p.name}</span>
  </Space>
}

function getUnit(order) {
  return order.unit ? `Unit: ${order.unit.number}` : ''
}

function getStatus(order) {
  let color;
  switch (order.status) {
    case "unassigned":
      color = "#f0ad4e";
      break;
    case "assigned":
      color = "#5bc0de";
      break;
    case "completed":
      color = "#5cb85c";
      break;
    case "cancelled":
      color = "#d9534f"
      break;
    default:
      color = "#5bc0de"
  }
  return <Tag color={color}>{titleize(order.status)}</Tag>
}

function getPriority(order) {
  if (order.priority === 3 || order.priority === 5) return <Tag color="red">{titleize(priorities[order.priority])}</Tag>
}

function pageSubTitle(order) {
  return <span>{getUnit(order)}{" "}{getStatus(order)}{" "}{getPriority(order)}</span>
}

function backIcon(showBack, goBack) {
  if (!showBack) return;
  return <i className={"fas fa-small fa-chevron-left cursor-pointer text-muted"} onClick={goBack} />
}

function pageHeader(order, showBack, goBack) {
  return <Space>
    {backIcon(showBack, goBack)}
    {pageTitle(order)}
    <small className={"text-muted"}>{pageSubTitle(order)}</small>
  </Space>
}

export {
  pageHeader
}
