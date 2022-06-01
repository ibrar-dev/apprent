import React, {useEffect, useState, useLayoutEffect} from "react";
import {List, Avatar, Rate, Popconfirm, Statistic, Space, Tag, Card} from "antd";
import {PlusCircleTwoTone, ExclamationCircleOutlined, CheckCircleOutlined, TabletTwoTone} from "@ant-design/icons";
import moment from 'moment';
import axios from "axios";
import actions from "../../../../actions";
import {UnassignedExtra, AssignedExtra, CompletedExtra} from './listItemExtra';
import formattedDuration from "../../../../../../utils/formattedDuration.js"

//We allow work orders that have been completed within 30 days to be calledback.

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

function filteredTechs(order, techs) {
  return techs.filter(t => {
    return checkTechOrder(t, order)
  })
}

function singleTech(tech, order) {
  if (!order.assignments) return true;
  const a = order.assignments[0];
  if (["completed", "cancelled"].includes(order.status)) return a.tech_id === tech.id
  return  true
}

function checkTechOrder(tech, order) {
  if (!tech || !tech.category_ids || !tech.property_ids) return false;
  return tech.category_ids.includes(order.category.id) &&
  tech.property_ids.includes(order.property_id) && singleTech(tech, order)
}

function confirmAssign(tech, orderId, setFinished) {
  actions.assignWorkOrders([orderId], tech.id)
  return setFinished("finished");
}

function extraAction(tech, order, setFinished) {
  if (order.status === "unassigned") return <UnassignedExtra tech={tech} order={order} setFinished={setFinished} />
  if (order.status === "assigned") return <AssignedExtra tech={tech} order={order} setFinished={setFinished} />
  if (order.status === "completed") return <CompletedExtra tech={tech} order={order} setFinished={setFinished} />
}

function extraTags(tech, order) {
  if (!order.assignments) return [""];
  const a = order.assignments[0];
  const callbacks = order.assignments.filter(a => a.status === "callback" && a.tech_id == tech.id);
  const activeTech = tech.id === a.tech_id;
  let tags = [];
  if (callbacks && callbacks.length >= 1) {
    tags.push({color: "warning", icon: <ExclamationCircleOutlined />, title: "Callback"})
  }
  if (activeTech && a.status === "assigned") {
    tags.push({color: "processing", icon: <TabletTwoTone />, title: "Currently Assigned"})
  }
  if (activeTech && a.status === "completed") {
    tags.push({color: "success", icon: <CheckCircleOutlined />, title: "Completed By"})
  }
  return <Space>
    {tags.map((t, i) => {
      return <Tag key={i} icon={t.icon} color={t.color}>{t.title}</Tag>
    })}
  </Space>
}

const AssignTech = ({order}) => {
  const [techs, setTechs] = useState([]);
  const [fetching, setFetching] = useState(false);
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
    if (finished === "finished") return location.reload();
  }, [finished]);

  return (
    <Card>
      <List itemLayout={"horizontal"}
        loading={fetching}
        size={"small"}
        renderItem={t => (
          <List.Item
            extra={<div className="cursor-pointer">{extraAction(t, order, setFinished)}</div>}
          >
            <List.Item.Meta
              avatar={t.image ? <Avatar src={t.image}/> : <Avatar>{techIcon(t.name)}</Avatar>}
              title={<span><a href={`/techs/${t.id}`}>{t.name}</a>{" "}{extraTags(t, order)}</span>}
              description={descriptionRender(t)}
            />
          </List.Item>
        )}
        pagination={{defaultPageSize: 50, position: "top", hideOnSinglePage: true}}
        dataSource={filteredTechs(order, techs)}
      />
    </Card>
  )
}

export default AssignTech
