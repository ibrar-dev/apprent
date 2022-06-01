import React, {useState} from 'react';
import {Card, Row, Col, Input, Button, Popconfirm} from  'antd';
import {SendOutlined} from "@ant-design/icons";
import axios from 'axios';

const CancelOrder = ({order, setChanged}) => {
  const [reason, setReason] = useState("");

  function cancelWorkOrder() {
    const promise = axios.patch(`/api/orders/${order.id}`, {reason});
    promise.finally(() => setChanged(true));
  }

  return <Card>
    <Row>
      <Col flex="auto">
        <Input.TextArea placeholder="Cancellation Reason"
                        value={reason}
                        style={{width: '100%'}}
                        onChange={e => setReason(e.target.value)} />
      </Col>
    </Row>
    <Row className="mt-3">
      <Col>
        <Popconfirm title={"Cancelling will email the resident the reason for cancellation."}
                    onConfirm={() => cancelWorkOrder()}
                    disabled={reason.length <= 5}
        >
          <Button
            type="primary"
            disabled={reason.length <= 5}
            icon={<SendOutlined style={{verticalAlign: "0.1rem"}}/>}
          >
            Submit
          </Button>
        </Popconfirm>
      </Col>
    </Row>
  </Card>
}

export default CancelOrder;
