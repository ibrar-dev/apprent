import React from 'react';
import internalLedger from "./internalLedger";
import externalLedger from './externalLedger';

const ledgerApp = ({tenant}) => {
  const ledgerBody = tenant.ledger_mode === "Yardi" ? externalLedger : internalLedger;
  return ledgerBody(tenant);
};

export default ledgerApp;