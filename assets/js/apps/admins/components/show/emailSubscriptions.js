import React, {useEffect, useState} from "react";
import { Row, Col, Collapse, Card, Space, Switch } from "antd";
import axios from "axios";

const { Panel } = Collapse;

function findSubscription(subs, trigger) {
  return subs.find((s) => s.trigger === trigger);
}

function switchButton(title, admin, subscriptions, trigger, setShouldUpdate) {
  const [fetching, setFetching] = useState(false);
  const [sub, setSub] = useState(findSubscription(subscriptions, trigger));

  useEffect(() => {
    const activeSub = findSubscription(subscriptions, trigger);
    setSub(activeSub);
  }, [subscriptions]);

  // Get admin data in here to see if shuold subscribe or unsub.
  function switchToggled() {
    const updateSubscription = async () => {
      setFetching(true);
      const result = await axios.patch(`/api/email_subscriptions/${admin.id}`, {[`${sub && sub.active ? "unsubscribe" : "subscribe"}`]: trigger});
      setFetching(false);
      setShouldUpdate(true);
    };
    updateSubscription();
  }

  return (
    <Space size="large">
      <p>{title}</p>
      <Switch 
        checked={sub ? sub.active : false}
        loading={fetching}
        onChange={() => switchToggled()}
      />
    </Space>
  )
}

const EmailSubscriptions = ({activeAdmin}) => {
  const [fetching, setFetching] = useState(false);
  const [data, setData] = useState([]);
  const [shouldUpdate, setShouldUpdate] = useState(true);

  useEffect(() => {
    if (shouldUpdate) {
      const fetchData = async () => {
        setFetching(true);
        const result = await axios(`/api/email_subscriptions/${activeAdmin.id}`);
        setData(result.data);
        setFetching(false);
        setShouldUpdate(false);
      };
      fetchData();
    }
  }, [shouldUpdate]);

  return (
    <Row>
      <Col span={24}>
        <Card
          className="w-100"
          title="Email Subscriptions"
        >
          <Collapse defaultActiveKey={"1"}>
            <Panel header="Payment Emails" key="1">
              <Row>
                <Col>
                  {switchButton("Daily Payments Email", activeAdmin, data, "daily_payments", setShouldUpdate)}
                </Col>
                <Col></Col>
                <Col></Col>
                <Col></Col>
              </Row>
            </Panel>
            <Panel header="Application Emails" key="2">
              <p>Coming Soon</p>
            </Panel>
          </Collapse>
        </Card>
      </Col>
    </Row>
  )
}

export default EmailSubscriptions;