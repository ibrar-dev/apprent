import React from "react";
import {
  Row, Col, Card, Spin
} from "antd";
import CategoryChart from "./categoryChart";
import PayeeChart from "./payeeChart";

const DateCharts = ({
  data, fetching
}) => (
  <div className="d-flex flex-column">
    <Row>
      <Col span={12}>
        <Card className="w-100" bordered={false} title="Expenses By Vendor">
          <Spin spinning={fetching}>
            <PayeeChart approvals={data} />
          </Spin>
        </Card>
      </Col>
      <Col span={12}>
        <Card className="w-100" bordered={false} title="Expenses By Category">
          <Spin spinning={fetching}>
            <CategoryChart approvals={data} />
          </Spin>
        </Card>
      </Col>
    </Row>
  </div>
);

export default DateCharts;
