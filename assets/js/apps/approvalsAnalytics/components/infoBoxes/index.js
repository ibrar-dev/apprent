import React, {useEffect, useState} from "react";
import axios from "axios";
import {Spin} from "antd";
import {toCurr, capsLock} from "../../../../utils";

function changeType(type, setType) {
  if (type === "ytd") return setType("mtd");
  return setType("ytd");
}

function extractField(data, type) {
  if (!data && type === "amount") return "0.00";
  if (!data) return "";
  return data[type];
}

const DetailedInfoBox = ({title, url, properties}) => {
  const [data, setData] = useState({mtd: {}, ytd: {}});
  const [fetching, setFetching] = useState(false);
  const [type, setType] = useState("mtd");

  useEffect(() => {
    if (properties && properties.length) {
      const fetchData = async () => {
        setFetching(true);
        const result = await axios(`/api/approvals_analytics?infoBox&properties=${properties}&type=${url}`);
        setData(result.data);
        setFetching(false);
      };
      fetchData();
    }
  }, [properties]);

  return (
    <Spin spinning={fetching}>
      <div className="d-flex flex-column cursor-pointer" onClick={() => changeType(type, setType)}>
        <p className="text-muted">{`${title} ${capsLock(type)}`}</p>
        <h4>{toCurr(extractField(data[type], "amount"))}</h4>
        <h6>{extractField(data[type], "name")}</h6>
      </div>
    </Spin>
  );
};

const InfoBox = ({title, url, properties}) => {
  const [data, setData] = useState({mtd: 0, ytd: 0});
  const [fetching, setFetching] = useState(false);
  const [type, setType] = useState("mtd");

  useEffect(() => {
    if (properties && properties.length) {
      const fetchData = async () => {
        setFetching(true);
        const result = await axios(`/api/approvals_analytics?infoBox&properties=${properties}&type=${url}`);
        setData(result.data);
        setFetching(false);
      };
      fetchData();
    }
  }, [properties]);

  return (
    <Spin spinning={fetching}>
      <div className="d-flex flex-column cursor-pointer" onClick={() => changeType(type, setType)}>
        <p className="text-muted">{`${title} ${capsLock(type)}`}</p>
        <h4>{toCurr(data[type])}</h4>
      </div>
    </Spin>
  );
};

const InfoBoxes = ({properties}) => {
  return (
    <div className="d-flex flex-wrap justify-content-between">
      <div className="d-flex flex-row justify-content-center mx-2 my-2">
        <InfoBox title="Pending Approval" url="pending_approval" properties={properties} />
      </div>
      <div className="d-flex flex-row justify-content-center mx-2 my-2">
        <InfoBox title="Approved" url="approved" properties={properties} />
      </div>
      <div className="d-flex flex-row justify-content-center mx-2 my-2">
        <InfoBox title="Denied" url="denied" properties={properties} />
      </div>
      <div className="d-flex flex-row justify-content-center mx-2 my-2">
        <InfoBox title="Approved Per Unit" url="approved_per_unit" properties={properties} />
      </div>
      <div className="d-flex flex-row justify-content-center mx-2 my-2">
        <DetailedInfoBox title="Most Expensed Category" url="most_expensed_category" properties={properties} />
      </div>
      <div className="d-flex flex-row justify-content-center mx-2 my-2">
        <DetailedInfoBox title="Most Expensed Vendor" url="most_expensed_payee" properties={properties} />
      </div>
    </div>
  );
};

export default InfoBoxes
