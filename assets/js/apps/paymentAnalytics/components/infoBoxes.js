import React, {useEffect, useState} from "react";
import axios from "axios";
import infoBox from "./infoBox";

// currency, data, title, toggle, loading

const initialData = {
  number_of_payments: {day_of: 0, mtd: 0},
  payments_amount: {day_of: 0, mtd: 0},
  tenants_with_autopay: 0,
  tenants_with_no_login: 0
}

function infoBoxes(properties) {
  const [data, setData] = useState({...initialData});
  const [fetching, setFetching] = useState(false);

  useEffect(() => {
    if (properties && properties.length) {
      const fetchData = async () => {
        setFetching(true);
        const result = await axios(`/api/payments_analytics?infoBoxes&properties=${properties}`);
        setData(result.data);
        setFetching(false);
      };
      fetchData();
    }
  }, [properties]);

  return (
    <div className="d-flex flex-wrap justify-content-between">
      <div className="d-flex flex-row justify-content-center mx-2 my-2">
        {infoBox(true, data.payments_amount, "Amount Collected", true, fetching)}
      </div>
      <div className="d-flex flex-row justify-content-center mx-2 my-2">
        {infoBox(false, data.number_of_payments, "Payments Made", true, fetching)}
      </div>
      <div className="d-flex flex-row justify-content-center mx-2 my-2">
        {infoBox(false, data.tenants_with_autopay, "Autopay Enabled", false, fetching)}
      </div>
      <div className="d-flex flex-row justify-content-center mx-2 my-2">
        {infoBox(false, data.tenants_with_no_login, "Not Yet Logged In", false, fetching)}
      </div>
    </div>
  )
}

export default infoBoxes;