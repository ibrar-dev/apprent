import React, {useState} from 'react';
import { Divider, List, InputNumber, Row, Col, Space, Button } from "antd";
import MaskedInput from 'react-text-mask';
import { titleize } from '../../../../utils';

function messagingComponent(numbers) {
  return (
    <div className="">
      <List 
        bordered
        dataSource={numbers}
        renderItem={(n) => (
          <List.Item>
            <List.Item.Meta title={titleize(n.context)} description={n.number} />
          </List.Item>
        )}
      />
    </div>
  )
};

const NewNumber = () => {
  const [number, setNumber] = useState("");
  const [context, setContext] = useState("all");

  return (
    <div className="d-flex flex-fill flex-row justify-space-between">
      <InputNumber stringMode min={0} max={9999999999} onChange={(e) => setNumber(e)} />
    </div>
  )
}

function phoneNumbers({property}) {
  const [loading, setLoading] = useState(false);

  return (
    <div>
      <Divider orientation="left">Text Messaging</Divider>
      <Row justify="end" align="middle" gutter={[8, 24]}>
        <Col>
          <Space size="small">
            <Button disabled>Purchase</Button>
            <Button disabled>Add</Button>
          </Space>
        </Col>
      </Row>
      <Row>
        <Col span={24}>
          {messagingComponent(property.phone_numbers)}
        </Col>
      </Row>
    </div>
  )
};

export default phoneNumbers;
