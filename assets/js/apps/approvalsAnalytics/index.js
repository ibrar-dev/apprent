import React from "react";
import ReactDOM from "react-dom";
import ApprovalsAnalyticsApp from "./components";

const container = document.getElementById("approvals-analytics-app");

if (container) {
  ReactDOM.render(<ApprovalsAnalyticsApp />, container);
}
