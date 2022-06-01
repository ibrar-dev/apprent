import React, {useEffect, useState} from "react";
import {connect} from "react-redux";
import {
  Space, Row, DatePicker, Card, Button, Modal,
} from "antd";
import {SearchOutlined} from "@ant-design/icons";
import moment from "moment";
import MultiPropertySelect from "../../../../components/multiPropertySelect";
import {getCookie} from "../../../../utils/cookies";
import actions from "../../actions";
import StatusTabs from "./statusTabs";
import NotesDisplay from "./notesDisplay";
import NewOrderDrawer from "./newOrderDrawer";

const {properties} = window;

const dateFormats = ["MM/DD/YY", "MM/DD/YYYY", "MM-DD-YY", "MM-DD-YYYY"];

function fetchOrders(pros, dates) {
  if (!pros.length) return;
  actions.fetchOrders(pros, [dates[0].format("YYYY-MM-DD"), dates[1].format("YYYY-MM-DD")]);
}

function Orders({skeleton, newOrders, orderData}) {
  const [dates, setDates] = useState([moment("2020-06-01"), moment()]);
  const [propertiesSelected, setPropertiesSelected] = useState([]);
  const [displayNewOrderForm, setDisplayNewOrderForm] = useState(false);
  const [key, setKey] = useState(1);

  useEffect(() => {
    setPropertiesSelected(getCookie("multiPropertySelect"));
  }, []);

  useEffect(() => {
    setKey(key + 1);
  }, [displayNewOrderForm]);

  useEffect(() => {
    fetchOrders(propertiesSelected, dates);
  }, [dates]);

  return (
    <Card className="w-100" title="Work Orders">
      <Space direction="vertical" size="large" className="w-100">
        <Row justify="space-between">
          <div className={`d-flex flex-row w-50 border border-success ${properties.length <= 1 ? "invisible" : "visible"}`}>
            <MultiPropertySelect
              selectProps={{loading: skeleton, bordered: false}}
              className="flex-fill"
              onChange={(p) => setPropertiesSelected(p)}
            />
            <Button
              onClick={() => fetchOrders(propertiesSelected, dates)}
              type="link"
              icon={<SearchOutlined style={{fontSize: 18}} />}
            />
          </div>
          <div className="d-flex flex row border border-secondary">
            {
              properties.length <= 1
              && (
                <Button
                  onClick={() => fetchOrders(propertiesSelected, dates)}
                  type="link"
                  icon={<SearchOutlined style={{fontSize: 18}} />}
                />
              )
            }
            <DatePicker.RangePicker
              allowClear={false}
              value={dates}
              bordered={false}
              format={dateFormats}
              onChange={setDates}
            />
          </div>
        </Row>
        <StatusTabs dates={dates} newOrders={newOrders} newOrderDrawer={setDisplayNewOrderForm} />
        {
          orderData
          && (
            <Modal
              title="Notes and Comments"
              onCancel={() => actions.setOrderData(null)}
              visible
              footer={null}
              destroyOnCloser
            >
              <NotesDisplay
                maxHeight={300}
                order={orderData}
                onNewNoteSuccess={() => fetchOrders(propertiesSelected, dates)}
              />
            </Modal>
          )
        }
        {
          displayNewOrderForm && (
            <NewOrderDrawer
              key={key}
              visible
              close={() => setDisplayNewOrderForm(false)}
              fetchOrders={() => fetchOrders(propertiesSelected, dates)}
            />
          )
        }
      </Space>
    </Card>
  );
}

export default connect(({skeleton, newOrders, orderData}) => ({skeleton, newOrders, orderData}))(Orders);
