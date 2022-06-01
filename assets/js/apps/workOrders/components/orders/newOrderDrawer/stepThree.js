import React, {useState} from "react";
import {
  Row, Col, Descriptions, Button, Result, Spin,
} from "antd";
import axios from "axios";

const {properties} = window;

const priorities = {
  0: "Standard",
  1: "Standard",
  2: "Standard",
  3: "Violation",
  4: "Standard",
  5: "Emergency",
};

const submitOrder = async (workOrder, setSubmitting, setResult, fetchOrders) => {
  setSubmitting(true);
  if (workOrder.tenant_id === "null") delete workOrder.tenant_id;
  if (workOrder.unit_id === "null") delete workOrder.tenant_id;
  const promise = axios.post("/api/orders", {workOrder});
  promise.then((r) => {
    setResult({status: "success", ...r.data});
    fetchOrders();
  });
  promise.catch((e) => {
    setResult({status: "error", message: e});
  });
  promise.finally(() => setSubmitting(false));
};

const successfullySavedTitle = (order) => {
  const p = properties.find((p) => p.id === order.property_id);
  return <span>Work Order Successfully Saved for {order.unit_number ? order.unit_number : p.name}</span>;
};

const successfullySavedSubTitle = (order, {order_data}) => (
  <div>
    {order.tenant_email && <p>Resident has been notified at {order.tenant_email}</p>}
    {order.unit_id && !order.tenant_email && <p>The resident in {order.unit_number} does not have an email address in the system and will be unable to get any updates for this request</p>}
    {order_data.id && <p>The work order can be viewed <a href={`/orders/${order_data.id}`} target="_blank">here</a></p>}
    {order_data.ticket && <p>The auto generated ticket is <a href={`/orders/${order_data.id}`} target="_blank">{order_data.ticket}</a></p>}
    {order.tech_name && <p>The work order has been assigned to {order.tech_name} and can be found under the assigned list</p>}
  </div>
);

const StepThree = ({order, setCurrent, closeDrawer, fetchOrders}) => {
  const property = properties.find(p => order.property_id === p.id);
  const [submitting, setSubmitting] = useState(false);
  const [result, setResult] = useState({});

  return (
    <Row className="w-100">
      <Col span={24}>
        <Row className="w-100">
          <Descriptions className="w-100" title="Summary" bordered column={2}>
            <Descriptions.Item label="Property">{property ? property.name : ""}</Descriptions.Item>
            <Descriptions.Item label="Unit">{order.unit_number ? order.unit_number : "N/A"}</Descriptions.Item>
            <Descriptions.Item label="Category">{order.category}</Descriptions.Item>
            <Descriptions.Item label="Entry Allowed">{order.entry_allowed ? "Yes" : "No"}</Descriptions.Item>
            <Descriptions.Item label="Pet in Unit">{order.has_pet ? "Yes" : "No"}</Descriptions.Item>
            <Descriptions.Item label="Priority">{priorities[order.priority]}</Descriptions.Item>
            <Descriptions.Item label="Assign To">{order.tech_name ? order.tech_name : "N/A"}</Descriptions.Item>
            <Descriptions.Item label="Description">{order.note}</Descriptions.Item>
          </Descriptions>
        </Row>
        {
          result.status !== "success" && (
            <Row justify="space-between" className="mt-3">
              <Button onClick={() => setCurrent(1)}>Back</Button>
              <Button onClick={() => submitOrder(order, setSubmitting, setResult, fetchOrders)} type="primary">Submit</Button>
            </Row>
          )
        }
        <Row className="w-100">
          {submitting && <Spin size="large" />}
          {
            result.status && (
              <Result
                status={result.status}
                className="w-100"
                extra={[
                  <Button onClick={closeDrawer} key="close">Close Form</Button>,
                ]}
                subTitle={result.status === "success" ? successfullySavedSubTitle(order, result) : result.message}
                title={result.status === "success" ? successfullySavedTitle(order) : "Something went wrong"}
              />
            )
          }
        </Row>
      </Col>
    </Row>
  );
};

export default StepThree;
