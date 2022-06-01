import React, {useEffect, useState, useLayoutEffect} from "react";
import {Drawer, List, Avatar, Row, Col, Descriptions, Rate, Popconfirm, Badge, Statistic, Space} from "antd";
import {PlusCircleTwoTone} from "@ant-design/icons";
import axios from "axios";
import TagsInput from "react-tagsinput";
import {safeRegExp} from "../../../../../utils";
import actions from "../../../actions";
import formattedDuration from "../../../../../utils/formattedDuration"
function techIcon(name) {
	return name.split(" ").map(n => n[0]).join("").toUpperCase()
}

function descriptionRender(tech) {
	return <Space size={"large"} direction={"horizontal"}>
		<Statistic title={"Current Orders"} value={tech.assignments || 0}/>
    <Statistic
      title={"Avg Completion"}
      value={formattedDuration(tech?.stats?.completion_time)}
    />
    <Space size={"small"} direction={"vertical"}>
	    <small>Rating</small>
	    {tech.stats ? <Rate disabled defaultValue={tech.stats.rating} /> : "N/A"}
    </Space>
	</Space>
}

function filteredTechs(orders, techs, tags) {
	return techs.filter(t => {
		return checkTech(t, orders) && checkTags(t, tags)
	})
}

function checkTech(tech, orders) {
	return orders.filter(o => checkTechOrder(tech, o)).length === orders.length
}

function checkTechOrder(tech, order) {
	if (!tech || !tech.category_ids || !tech.property_ids) return false;
	return tech.category_ids.includes(order.category_id) && tech.property_ids.includes(order.property_id)
}

function checkTags(tech, tags) {
	const checked = tags.map(t => checkTag(tech, t));
	return checked.every(t => t === true)
}

function checkTag(tech, tag) {
	const filter = safeRegExp(tag);
	return filter.test(tech.name) || filter.test(tech.email)
}

function confirmAssign(tech, selected, setFinished, addAttribute) {
	if (addAttribute) {
		addAttribute({tech: tech.id, tech_name: tech.name});
		return setFinished("addFinished")
	}
	const order_ids = selected.map(o => o.id);
	actions.assignWorkOrders(order_ids, tech.id)
	return setFinished("finished");
}

//REMOVE THIS MONTHS STATS AND DISPLAY HOW MANY CURRENTLY ASSIGNED WORK ORDERS THIS TECH HAS

const AssignDrawer = ({selected, visible, close, closeAndClear, addAttribute}) => {
	const [techs, setTechs] = useState([]);
	const [fetching, setFetching] = useState(false);
	const [tags, setTags] = useState([]);
	const [finished, setFinished] = useState(null);

	useLayoutEffect(() => {
		const fetchTechs = async () => {
			setFetching(true);
			const result = await axios("/api/techs?assign");
			setTechs(result.data);
			setFetching(false);
		};

		fetchTechs()
	}, []);

	useEffect(() => {
		if (finished === "finished") return closeAndClear
		return () => close
	}, [finished]);

  return (
    <Drawer
      title={"Assign Work Orders"}
      placement={"left"}
      width={760}
      onClose={close}
      visible={visible}
      closable={true}
    >
      <TagsInput value={tags} onChange={setTags} onlyUnique className="react-tagsinput" inputProps={{
        className: "react-tagsinput-input",
        placeholder: "Add a search term",
        style: {width: "auto"}
      }}/>
    <List itemLayout={"horizontal"}
      loading={fetching}
      size={"small"}
      renderItem={t => (
        <List.Item
          extra={<Popconfirm
            title={`Assign these ${selected.length} orders to ${t.name}`}
            onConfirm={() => confirmAssign(t, selected, setFinished, addAttribute)}
          >
            <PlusCircleTwoTone
              style={{fontSize: 28}}
              twoToneColor={"#28a745"}
            />
          </Popconfirm>}>
          <List.Item.Meta
            avatar={t.image ? <Avatar src={t.image}/> : <Avatar><i class="fas fa-exclamation-circle"></i></Avatar>}
            title={<a href={`/techs/${t.id}`}>{t.name}</a>}
            description={descriptionRender(t)}
          />
        </List.Item>
      )}
      pagination={{defaultPageSize: 50, position: "top"}}
      dataSource={filteredTechs(selected, techs, tags)}/>
  </Drawer>
  );
}

export default AssignDrawer
