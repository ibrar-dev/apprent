import React, {useState, useEffect} from 'react';
import moment from 'moment';
import {Descriptions, Select, Space} from 'antd';
import {CheckCircleTwoTone, CloseCircleTwoTone} from '@ant-design/icons';
import axios from 'axios';
import UnassignedDescription from './unassigned.js';
import AssignedDescription from './assigned.js';
import CompletedDescription from './completed.js';
import CancelledDescription from './cancelled.js';

function residentRender(tenant) {
	return <a href={`${window.url}/tenants/${tenant.id}`} target={"_blank"}>{tenant.first_name}{" "}{tenant.last_name}</a>
}

function residentEmail({id, email}) {
	return <a href={`${window.url}/tenants/${id}`} target={"_blank"}>{email}</a>
}

function alarmCode(order) {
	if (order.tenant && order.tenant.alarm_code) return order.tenant.alarm_code;
	if (!order.tenant) return "N/A"
	return "Not Provided"
}

function dateTimeRender(data) {
	return moment.utc(data).local().format("MM/DD/YY h:mmA")
}

function unitRender(unit) {
	return <Space direction={"vertical"}>
		<Space>
			<span>Number:</span>
			<span>{unit.number}</span>
		</Space>
		<Space>
			<span>Status:</span>
			<span>{unit.status}</span>
		</Space>
		<Space>
			<span>Floor Plan:</span>
			<span>{unit.floor_plan}</span>
		</Space>
		<Space>
			<span>Sq Footage:</span>
			<span>{unit.area}</span>
		</Space>
	</Space>
}

const priorities = {0: "Standard", 1: "Standard", 2: "Standard", 3: "Violation", 4: "Standard", 5: "Emergency"}

const StaticRender = ({order, attr}) => {
	return order[attr] ? <CheckCircleTwoTone style={styles.icon} twoToneColor={"#5cb85c"} /> : <CloseCircleTwoTone style={styles.icon} twoToneColor={"#d9534f"} />
}

function editableItemBool(edit, order, setChanged, name, attr) {
	const [field, setField] = useState(order[attr]);

	useEffect(() => {
		if (field !== order[attr]) {
			const promise = axios.patch(`/api/orders/${order.id}`, {workOrder: {[attr]: field}});
	    promise.then(() => setChanged(true));
		}
	}, [field])

	return (
		<Descriptions.Item label={<span style={styles.label}>{name}</span>}>
			{!edit && <StaticRender order={order} attr={attr} />}
			{edit && <Space>
				<Select style={styles.select} defaultValue={field} onChange={setField}>
					<Select.Option value={false}>No</Select.Option>
					<Select.Option value={true}>Yes</Select.Option>
				</Select>
			</Space>}
		</Descriptions.Item>
	)
}

function editableItemPriority(edit, order, setChanged, name, attr) {
	const [field, setField] = useState(order[attr]);

	useEffect(() => {
		if (field !== order[attr]) {
			const promise = axios.patch(`/api/orders/${order.id}`, {workOrder: {[attr]: field}});
	    promise.then(() => setChanged(true));
		}
	}, [field])

	return (
		<Descriptions.Item label={<span style={styles.label}>{name}</span>}>
			{!edit && priorities[order.priority]}
			{edit && <Space>
				<Select style={styles.select} defaultValue={priorities[field]} onChange={setField}>
					<Select.Option value={1}>Standard</Select.Option>
					<Select.Option value={3}>Violation</Select.Option>
					<Select.Option value={5}>Emergency</Select.Option>
				</Select>
			</Space>}
		</Descriptions.Item>
	)
}

function editableItemCategory(edit, order, setChanged, name, attr) {
	const [field, setField] = useState(order.category.id);
	const [fetching, setFetching] = useState(false);
	const [categories, setCategories] = useState([]);

	const fetchCategories = async () => {
    setFetching(true);
    const promise = axios.get(`/api/categories?assign`);
    promise.then(r => setCategories(r.data));
    promise.catch(() => snackbar({message: `Unable to get categories`, args: {type: "warn"}}));
    promise.finally(() => setFetching(false))
  }

	useEffect(() => {
		if (edit) {
			fetchCategories();
		}
	}, [edit]);

	useEffect(() => {
		if (field !== order.category.id) {
			const promise = axios.patch(`/api/orders/${order.id}`, {workOrder: {category_id: field}});
	    promise.then(() => setChanged(true));
		}
	}, [field])

	return (
		<Descriptions.Item label={<span style={styles.label}>{name}</span>}>
			{!edit && <span>
				<small>{order.category.parent_name} - </small>
				<b>{order.category.category}</b>
			</span>}
			{edit && <Space>
				<Select value={field} onChange={setField}>
					{categories.map(c => {
						return <Select.Option key={c.id} value={c.id}>
							<span>
								<small>{c.parent} - </small>
								<b>{c.name}</b></span>
						</Select.Option>
					})}
				</Select>
			</Space>}
		</Descriptions.Item>
	)
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


export {
	UnassignedDescription,
	AssignedDescription,
	CompletedDescription,
	CancelledDescription,
	residentRender,
	alarmCode,
	residentEmail,
	unitRender,
	dateTimeRender,
	priorities,
	editableItemBool,
	editableItemPriority,
	editableItemCategory
}
