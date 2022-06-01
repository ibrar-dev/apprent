import React, {useEffect, useState} from "react";
import {Row, Col, Button, Select, Spin, Form, Checkbox} from "antd";
import axios from "axios";
import AssignDrawer from "../assignDrawer";
import Uploader from "../../../../../components/uploader";

const {properties} = window;

function propertyCategory(categories, order) {
  if (!order || !order.category_id) return false;
  const cat = categories.find((c) => c.id === order.category_id);
  return cat.parent.includes("Property");
}

function filteredUnits(order, units) {
  if (!order.property_id) return units;
  return units.filter((u) => u.property_id === order.property_id);
}

const stringifyUnit = (u) => (
  JSON.stringify({
    property_id: u.property_id,
    unit_id: u.id,
    tenant_id: u.tenant_id,
    unit_number: u.number,
    tenant_email: u.email,
    allow_sms: u.allow_sms !== false && !!u.phone,
    actual: u.allow_sms,
    phone: u.phone,
  })
);

// search units function, choose property based on that. If propertyCategory do not display unit selection.
// search units based on timeout in typing, same as on stepOne.
// params on this page: entry_allowed, has_pet, priority, assign if canEdit(["Super Admin", "Regional", "Admin", "Tech"])

const StepTwo = ({addAttribute, setCurrent, order, categories}) => {
  const propertyCat = propertyCategory(categories, order);
  const [unitSearch, setUnitSearch] = useState("");
  const [unit, setUnit] = useState(null);
  const [units, setUnits] = useState([]);
  const [fetching, setFetching] = useState(false);
  const [techDrawer, setTechDrawer] = useState(false);
  const [attachment, setAttachment] = useState();

  useEffect(() => {
    if (attachment) {
      attachment.upload().then(() => {
        addAttribute({attachment: {uuid: attachment.uuid}});
      });
    }
  }, [attachment]);

  useEffect(() => {
    if (propertyCategory(categories, order) && properties.length === 1) {
      addAttribute({property_id: properties[0].id});
    }
  }, []);

  useEffect(() => {
    if (unitSearch.length >= 2) {
      const handler = setTimeout(async () => {
        setFetching(true);
        const result = await axios(`/api/units?minSearch=${unitSearch}`);
        setUnits(filteredUnits(order, result.data));
        setFetching(false);
      }, 500);
      return () => clearTimeout(handler);
    }
  }, [unitSearch]);

  useEffect(() => {
    if (unit) {
      const params = JSON.parse(unit);
      addAttribute({...params});
    }
  }, [unit]);

  return (
    <Row className="w-100 mt-3">
      <Col span={24}>
        <Row className="w-100" justify="space-between">
          <Col span={10}>
            <Form.Item label="Property">
              <Select
                placeholder={propertyCat ? "Property Select" : "Enter a Unit to the right"}
                disabled={!propertyCat}
                value={order.property_id}
                onChange={(p) => addAttribute({property_id: p})}
              >
                {properties.map((p) => (
                  <Select.Option key={p.id} value={p.id}>{p.name}</Select.Option>
                ))}
              </Select>
            </Form.Item>
          </Col>
          <Col span={10}>
            <Form.Item label="Unit">
              <Select
                showSearch
                showArrow={false}
                loading={fetching}
                onChange={setUnit}
                onSearch={setUnitSearch}
                disabled={propertyCat}
                filterOption={false}
                notFoundContent={fetching ? <Spin size="small" /> : "No Units Found"}
                placeholder={propertyCat ? "Property Category" : "Search Unit"}
              >
                {
                  units.length && units.map((u) => (
                    <Select.Option key={u.id} value={stringifyUnit(u)}>
                      {u.property}
                      {" "}
                      -
                      {" "}
                      {u.number}
                    </Select.Option>
                  ))
                }
              </Select>
            </Form.Item>
          </Col>
        </Row>
        <Row justify="space-between">
          <Col span={5}>
            <Form.Item label="Send Text Updates">
              <Checkbox
                value={order.allow_sms}
                disabled={!JSON.parse(unit)?.allow_sms}
                onChange={() => addAttribute({allow_sms: !order.allow_sms})}
                checked={order.allow_sms}
              />
            </Form.Item>
          </Col>
          <Col span={5}>
            <Form.Item label="Entry Allowed">
              <Checkbox
                value={order.entry_allowed}
                disabled={propertyCat}
                onChange={() => addAttribute({entry_allowed: !order.entry_allowed})}
                checked={order.entry_allowed}
              />
            </Form.Item>
          </Col>
          <Col span={5}>
            <Form.Item label="Pet in Unit">
              <Checkbox
                value={order.has_pet}
                disabled={propertyCat}
                onChange={() => addAttribute({has_pet: !order.has_pet})}
                checked={order.has_pet}
              />
            </Form.Item>
          </Col>
          <Col span={9}>
            <Form.Item label="Status">
              <Select defaultValue={order.priority} onChange={(s) => addAttribute({priority: s})}>
                <Select.Option value={1}>Standard</Select.Option>
                <Select.Option value={3}>Violation</Select.Option>
                <Select.Option value={5}>Emergency</Select.Option>
              </Select>
            </Form.Item>
          </Col>
        </Row>
        <Row justify="space-between">
          <Col span={12}>
            <Form.Item label="Assign">
              <Button disabled={!order.property_id} onClick={() => setTechDrawer(true)}>
                Assign To
                {" "}
                {order.tech_name ? order.tech_name : "Tech"}
              </Button>
            </Form.Item>
          </Col>
          <Col span={12}>
            <Form.Item label="Attach Image">
              <Uploader onChange={setAttachment} />
            </Form.Item>
          </Col>
        </Row>
      </Col>
      <AssignDrawer
        visible={techDrawer}
        addAttribute={addAttribute}
        close={() => setTechDrawer(false)}
        selected={[{property_id: order.property_id, category_id: order.category_id}]}
      />
      <Button className="mr-auto mt-2" onClick={() => setCurrent(0)}>Back</Button>
      <Button disabled={!order.property_id} className="ml-auto mt-2" onClick={() => setCurrent(2)}>Next</Button>
    </Row>
  );
};

export default StepTwo;
