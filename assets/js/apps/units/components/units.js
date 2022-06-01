import React, {useState} from "react";
import {
  Row, Col, Space, Table, Skeleton, Card, Button, Tag, List, Statistic,
} from "antd";
import {EyeOutlined} from "@ant-design/icons";
import {connect} from "react-redux";
import TagsInput from "react-tagsinput";
import moment from "moment";
import actions from "../actions";
import PropertySelect from "../../../components/propertySelect";
import {safeRegExp, toCurr, percentageCalculator} from "../../../utils";
import {sortableStringColumn} from "./functions";
import NewUnit from "./newUnit";
import canEdit from "../../../components/canEdit";

const columns = [
  {title: "", render: (unit) => (actionRenderer(unit))},
  {title: "Number", dataIndex: "number", simpleSort: true},
  {title: "Status", dataIndex: "status", simpleSort: true},
  {title: "Floor Plan", dataIndex: "floor_plan", simpleSort: true},
  {
    title: <Space size="small" direction="vertical">
            <small>Market Rent</small>
            Current Rent
           </Space>,
    dataIndex: "market_rent",
    simpleSort: true,
    render: (mr, unit) => (mrRenderer(mr, unit))
  },
  {title: "Current Lease", dataIndex: "current_lease", render: (data) => (leaseRenderer(data[0]))},
  {title: "Upcoming Leases", dataIndex: "future_leases", render: (data) => (multiLeases(data))},
  {title: "Past", dataIndex: "past_leases", render: (data) => (multiLeases(data))}
];

function mrRenderer(mr, unit) {
  let current_rent = 0;
  if (unit.current_lease && unit.current_lease[0] && unit.current_lease[0].current_rent) {
    current_rent = unit.current_lease[0].current_rent;
  }
  const percent = percentageCalculator(mr, current_rent).toFixed(0);
  return (
    <Statistic
      title={toCurr(mr)}
      value={toCurr(current_rent)}
      suffix={`${percent}%`}
      valueStyle={{color: percent >= 90 ? "#5dbd77" : "#dc3545"}}
      groupSeperator="/"
    />
  );
}

function checkResidents(unit, filter) {
  if (!unit.leases || !unit.leases.length) return false;
  const filtered = unit.leases.filter((l) => l.tenants.filter((t) => filter.test(t.full_name)).length >= 1);
  return filtered.length >= 1;
}

function checkTag(unit, tag) {
  const filter = safeRegExp(tag);
  // if (filter.test('haprent')) return unit
  return filter.test(unit.number) || filter.test(unit.status)
    || filter.test(unit.market_rent) || filter.test(unit.floor_plan)
    || checkResidents(unit, filter);
}

function checkTags(unit, tags) {
  if (!tags || tags.length === 0) return true;
  const checked = tags.map((t) => checkTag(unit, t));
  return checked.every((t) => t === true);
}

function filteredUnits(tags, units) {
  return units.filter((u) => checkTags(u, tags))
}





function mergedColumns() {
  return columns.map((c) => {
    if (c.simpleSort) {
      return {...c, ...sortableStringColumn(c.dataIndex)}
    } else {
      return c
    }
  })
}

function actionRenderer(unit) {
  return <Space size={"small"}>
    <Button type={"link"} icon={<EyeOutlined/>} href={`/units/${unit.id}`} />
    {/*{canEdit(["Super Admin"]) && <Button type={"link"} icon={<CloseOutlined style={{color: "red"}}/>}/>}*/}
  </Space>
}

function multiLeases(leases) {
  if (!leases.length) return <div />;
  return (
    <List
      renderItem={lease => (
        <List.Item>
          {leaseRenderer(lease)}
        </List.Item>
      )}
      size={"small"}
      pagination={{defaultPageSize: 1, size: "small", hideOnSinglePage: true}}
      dataSource={leases}
    />
  )
}

function leaseRenderer(lease) {
  if (!lease || !lease.start_date || !lease.end_date || !lease.tenants) return <div />;
  return <Space size={"small"} direction={"vertical"}>
    <Space size={"small"} direction={"horizontal"}>
      <Tag color={lease.haprent ? "volcano" : "cyan"}>{moment(lease.start_date).format("MM/DD/YY")} - {moment(lease.actual_move_out || lease.end_date).format("MM/DD/YY")}</Tag>
      {lease.tenants.map(t => (<Tag key={t.id} color={lease.haprent ? "volcano" : "cyan"} ><a href={`/tenants/${t.id}`}>{t.full_name}</a></Tag>))}
    </Space>
    {lease.move_out_date && !lease.actual_move_out && <Tag>Expected Move Out: {moment(lease.move_out_date).format("MM/DD/YY")}</Tag>}
  </Space>
}

function Units({skeleton, units, property, properties}) {
  const [tags, setTags] = useState([]);
  const [newUnit, setNewUnit] = useState(false);

  if (properties.length == 0) {
    return <div>Loading</div>
  }

  return <Card className={"w-100"} title={"Units"}>
    <Row justify={"space-between"}>
      <Col>
        <PropertySelect property={property} properties={properties} onChange={actions.viewProperty}/>
      </Col>
      <Col>
        <Space>
          <TagsInput value={tags} onChange={setTags} onlyUnique className="react-tagsinput" inputProps={{className: 'react-tagsinput-input', placeholder: 'Add a search term', style: {width: 'auto'}}} />
          {canEdit(["Super Admin"]) && <Button type={"link"} onClick={() => setNewUnit(!newUnit)}>+</Button>}
        </Space>
      </Col>
    </Row>
    <Row>
      <Col span={24}>
        {newUnit && <NewUnit toggle={() => setNewUnit(!newUnit)} property={property}/>}
        {skeleton && <Skeleton active={true} paragraph={{paragraph: 10, width: '100%'}} />}
        {!skeleton && <Table className={"w-100"}
                             dataSource={filteredUnits(tags, units)}
                             rowKey={u => u.id}
                             pagination={{defaultPageSize: 25, position: ['topRight'], showTotal: (total) => (`${total} Units`)}}
                             columns={mergedColumns()}
                             size={"small"} />}
      </Col>
    </Row>
  </Card>
}

export default connect(({skeleton, units, property, properties}) => {
  return {skeleton, units, property, properties}
})(Units)
