import React, {useState, useEffect, useLayoutEffect} from "react";
import axios from "axios";
import {RingLoader} from "react-spinners";
import {Card, CardHeader, CardBody, Button} from "reactstrap";
import yardiLedger from "./yardi";
// import ledgerSwitch from "../ledgerSwitch";
import offerTextPay from "../offerTextPay";

function externalLedger(tenant) {
  const [entries, setEntries] = useState([]);
  const [fetching, setFetching] = useState(false);

  useLayoutEffect(() => {
    const fetchLedgerEntries = async () => {
      setFetching(true);
      const result = await axios(`/api/external_ledgers/${tenant.external_id}`);
      setEntries(result.data);
      setFetching(false);
    };

    fetchLedgerEntries();
  }, []);

  if (fetching) {
    return (
      <div className="d-flex flex-fill justify-content-center">
        <RingLoader size={65} color="#5dbd77" />
      </div>
    )
  }

  if (!fetching && entries.length < 1) {
    return (
      <div className="d-flex flex-fill justify-content-center">
        <h5>No Ledger Data To Display :(</h5>
      </div>
    )
  }

  if (tenant.ledger_mode === "Yardi") {
    return yardiLedger(entries)
  }

  return
}

function externalLedgerBody(tenant) {
  return <Card className="ml-3">
    <CardHeader className="d-flex justify-content-between align-items-center pr-2">
      <Button size="sm" color="info">
        {tenant.closed && <i className="fas fa-lock"/>} Unit {tenant.unit.number}
      </Button>
      {offerTextPay(tenant.tenant_id)}
    </CardHeader>
    <CardBody>
      {externalLedger(tenant)}
    </CardBody>
  </Card>
}

export default externalLedgerBody;