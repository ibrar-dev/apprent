import React, {useState} from "react";
import {Spin} from "antd";
import {toCurr, capsLock} from "../../../utils";

function changeType(type, setType, toggle) {
  if (!toggle) return;
  if (type === "day_of") return setType("mtd");
  return setType("day_of");
}

function displayValue(currency, data, type, toggle) {
  if (currency && toggle) return toCurr(data[type]);
  if (!currency && toggle) return data[type];
  return data;
}

function displayType(type, currency) {
  if (type === "day_of" && currency) return "Today";
  if (!currency) return "";
  return capsLock(type);
}

function infoBox(currency, data, title, toggle, loading) {
  const [type, setType] = useState("day_of");

  return (
    <Spin spinning={loading}>
      <div className={`d-flex flex-column ${toggle ? 'cursor-pointer' : ''}`} onClick={() => changeType(type, setType, toggle)}>
        <p className="text-muted">{`${title} ${displayType(type, currency)}`}</p>
        <h4>{displayValue(currency, data, type, toggle)}</h4>
      </div>
    </Spin>
  )
}

export default infoBox;