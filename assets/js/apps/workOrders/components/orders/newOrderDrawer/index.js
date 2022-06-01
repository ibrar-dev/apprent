import React, {useEffect, useState} from "react";
import {connect} from "react-redux";
import {Drawer, Steps} from "antd";
import {StepOne, StepTwo, StepThree} from "./steps";

const {Step} = Steps;

const steps = [
  {title: "Start", description: "Describe the request"},
  {title: "Details", description: "Fill in the details"},
  {title: "Summary", description: "Review"},
];

const dataExists = (order, field, length) => {
  if (!order) return false;
  if (!length) return typeof order[field] !== "undefined";
  return (typeof order[field] !== "undefined") && order[field].length >= 1;
};

const verifyStepOne = (order) => {
  const checked = ["note", "category_id"].map((f) => dataExists(order, f, false));
  return checked.every((t) => t === true);
};

const verifyStepTwo = (order) => {
  const checked = ["entry_allowed", "priority", "has_pet", "property_id"].map((f) => dataExists(order, f, false));
  return checked.every((t) => t === true);
};

const checkIfDisabled = (order, index) => {
  if (index === 0) return false;
  if (index === 1) return !verifyStepOne(order);
  if (index === 2) return !verifyStepTwo(order);
  return true;
};

const initialOrderValue = {
  entry_allowed: false,
  allow_sms: false,
  has_pet: false,
  priority: 1,
};

const NewOrderDrawer = ({visible, close, fetchOrders, subcategories}) => {
  const [order, setOrder] = useState({...initialOrderValue});
  const [attr, addAttr] = useState(null);
  const [current, setCurrent] = useState(0);

  useEffect(() => {
    setOrder({...order, ...attr});
  }, [attr]);

  return (
    <Drawer
      title="Submit New Request"
      placement="right"
      width={760}
      onClose={close}
      visible={visible}
      closable
    >
      <Steps current={current} onChange={setCurrent}>
        {
          steps.map((s, i) => (
            <Step
              key={s.title}
              title={s.title}
              description={s.description}
              disabled={checkIfDisabled(order, i)}
            />
          ))
        }
      </Steps>
      <div className="mt-2">
        {
          current === 0
          && (
            <StepOne
              addAttribute={addAttr}
              categories={subcategories}
              order={order}
              setCurrent={setCurrent}
            />
          )
        }
        {
          current === 1
          && (
            <StepTwo
              addAttribute={addAttr}
              categories={subcategories}
              order={order}
              setCurrent={setCurrent}
            />
          )
        }
        {
          current === 2
          && (
            <StepThree
              addAttribute={addAttr}
              categories={subcategories}
              order={order}
              setCurrent={setCurrent}
              closeDrawer={close}
              fetchOrders={fetchOrders}
            />
          )
        }
      </div>
    </Drawer>
  );
};

export default connect(({subcategories}) => ({subcategories}))(NewOrderDrawer);
