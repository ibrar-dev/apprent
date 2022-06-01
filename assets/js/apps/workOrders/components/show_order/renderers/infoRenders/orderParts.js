import React, {useState} from 'react';
import {List, Steps, Card, Row, Col, Input, Select, Button} from  'antd';
import axios from 'axios';

const statuses = {'pending': 0, 'ordered': 1, 'delivered': 2, 'cancelled': -1}

function getStep(status) {
  switch (status) {
    case 'pending':
      return 0;
    case 'ordered':
      return 1;
    case 'delivered':
      return 2;
    default:
      return 0;
  }
}

const AddPart = ({orderId, setChanged}) => {
  const [name, setName] = useState("");
  const [status, setStatus] = useState("pending");

  function addPart() {
    const part = {name: name, status: status, order_id: orderId}
    const promise = axios.post(`/api/maintenance_parts`, part);
    promise.finally(() => setChanged(true))
  }

  return <Card title="New Part">
    <Row justify="start">
      <Col>
        <Select size="large" defaultValue={status} onChange={setStatus} >
          <Select.Option value="pending">Pending</Select.Option>
          <Select.Option value="ordered">Ordered</Select.Option>
          <Select.Option value="delivered">Delivered</Select.Option>
        </Select>
      </Col>
      <Col flex="auto">
        <Input size="large" defaultValue={name} onChange={e => setName(e.target.value)} placeholder="Name" style={{width: '100%'}} /></Col>
      <Col>
        <Button onClick={() => addPart()} disabled={name.length <= 3} size="large" block>Add Part</Button>
      </Col>
    </Row>
  </Card>
}

const PartRender = ({part, setChanged}) => {
  const [cancelled, _setCancelled] = useState(part.status === 'cancelled')
  function changeStatus(status) {
    const newStatus = Object.keys(statuses).find(k => statuses[k] === status);
    const promise = axios.patch(`/api/maintenance_parts/${part.id}`, {part: {status: newStatus}});
    promise.finally(r => setChanged(true))
  }

  return <Card title={part.name} extra={<i onClick={() => changeStatus(-1)} className={`fas fa-trash text-danger cursor-pointer`} />}>
    <Steps current={cancelled ? 1 : statuses[part.status]} onChange={current => changeStatus(current)}>
      <Steps.Step title="Pending" description={statuses[part.status] == 0 ? "Part has not yet been ordered." : "Part has been ordered"} />
      <Steps.Step title={cancelled ? 'Cancelled' : 'Ordered'} status={cancelled ? 'error' : ''}  description={cancelled ? "Part has been cancelled." : "Part has been ordered."} />
      <Steps.Step title="Delivered" description={statuses[part.status] == 2 ? "Part has arrived and order can now be completed." : "Part has not yet arrived"} />
    </Steps>
  </Card>
}

const OrderParts = ({order, setChanged}) => {
  console.log(order)
  return <Card>
    <List dataSource={order.parts}
          header={(order.status === "unassigned" || order.status === "assigned") && <AddPart orderId={order.id} setChanged={setChanged} />}
          renderItem={item => (
            <PartRender key={item.id} part={item} setChanged={setChanged} />
          )} />
  </Card>
}

export default OrderParts
