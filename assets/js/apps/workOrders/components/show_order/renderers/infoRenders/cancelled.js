import React, {useState} from 'react';
import {Descriptions, Col, Divider, Select, Rate} from 'antd';
import {CheckCircleTwoTone, CloseCircleTwoTone} from '@ant-design/icons';
import moment from 'moment';
import {titleize} from "../../../../../../utils";
import {residentRender, alarmCode, residentEmail, editableItemPriority,
	unitRender, dateTimeRender, priorities, editableItemBool, editableItemCategory} from './index.js';
import AssignTech from "./assignTech";
import NotesDisplay from "./notesDisplay";
import OrderParts from "./orderParts";
import CancelOrder from "./cancelOrder";

const {Item} = Descriptions;

function cancelItem(order, field) {
  if (!order.cancellation) return ""
	if (field === "time") return <Item span={4} label={<span style={styles.label}>Cancellation {titleize(field)}</span>}>{moment().utc(order.cancellation[field]).local().format("MM/DD/YY h:mmA")}</Item>
  return <Item span={4} label={<span style={styles.label}>Cancellation {titleize(field)}</span>}>{order.cancellation[field]}</Item>
}

function callbackItem(order) {
	if (!order.assignments) return
	const callbacks = order.assignments.filter(a => a.status === "callback");
	if (!callbacks.length) return
	return callbacks.map(c => {
		return <Item span={4} key={c.id}><b>Callback</b> by {c.tech} on <b>{moment.utc(c.updated_at).local().format("MM/DD/YY h:mmA")}</b></Item>
	})
}

const CancelledDescription = ({order, action, setAction, setChanged, edit}) => {
	return <>
		<Col sm={{span: 24}} md={{span: 12}}>
			<Divider orientation="left" style={{ color: '#333', fontWeight: 'normal' }}>
				{titleize(action)}
			</Divider>
			<div className={"pr-4"}>
				{action === "technicians" && <AssignTech order={order} />}
				{action === "notes" && <NotesDisplay order={order} setChanged={setChanged} />}
				{action === "parts" && <OrderParts order={order} setChanged={setChanged} />}
				{action === "cancel" && <CancelOrder order={order} setChanged={setChanged} />}
			</div>
		</Col>
		<Col sm={{span: 24}} md={{span: 12}}>
			<Divider orientation="left" style={{ color: '#333', fontWeight: 'normal' }}>
				Information
			</Divider>
			<div className={"pl-4"}>
				<Descriptions bordered column={2}>
          {cancelItem(order, "reason")}
          {cancelItem(order, "admin")}
          {cancelItem(order, "time")}
					{callbackItem(order)}
          <Item span={4} />
					<Item label={<span style={styles.label}>Received</span>}>{dateTimeRender(order.inserted_at)}</Item>
					{order.unit && <Item label={<span style={styles.label}>Unit</span>}>{unitRender(order.unit)}</Item>}
					{order.tenant && <Item label={<span style={styles.label}>Resident</span>}>{residentRender(order.tenant)}</Item>}
					{order.tenant && <Item label={<span style={styles.label}>Email</span>}>{residentEmail(order.tenant)}</Item>}
					{editableItemBool(edit, order, setChanged, "Pet In Unit", "has_pet")}
					{editableItemBool(edit, order, setChanged, "Entry Allowed", "entry_allowed")}
					{editableItemBool(edit, order, setChanged, "SMS Updates", "allow_sms")}
					<Item label={<span style={styles.label}>Alarm Code</span>}>{alarmCode(order)}</Item>
					{editableItemPriority(edit, order, setChanged, "Priority", "priority")}
					{editableItemCategory(edit, order, setChanged, "Category", "category_id")}
				</Descriptions>
			</div>
		</Col>
	</>
}

const styles = {
	icon: {
		fontSize: 24
	},
	label: {
		fontSize: 16
	},
	select: {
		width: '100%'
	}
}

export default CancelledDescription;
