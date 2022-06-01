import React, {useState, useEffect} from "react";
import { Button } from "antd";
import { CheckOutlined } from "@ant-design/icons";
import axios from "axios";

export default (tenantId) => {
  const [cooldown, setCooldown] = useState(false);
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState(null);

  function actuallyOffer() {
    setLoading(true);
    const promise = axios.get(`/api/text_messages/${tenantId}?offer_text_pay`);
    promise.then(() => {
      setResult("done");
    });
    promise.catch((e) => {
      setResult(e.response.data.error);
    });
    promise.finally(() => {
      setLoading(false);
      setCooldown(true);
    })
  }

  useEffect(() => {
    if (result && result !== "done") {
      return alert(result);
    }
  }, [result])

  return (
    <Button
      loading={loading}
      type={"primary"}
      disabled={cooldown}
      onClick={() => actuallyOffer()}
      icon={result == "done" ? <CheckOutlined /> : null}
    >
      Offer TextPay
    </Button>
  )
};
