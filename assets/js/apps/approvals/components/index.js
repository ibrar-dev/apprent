import React from "react";
import {Switch, Route, withRouter} from "react-router-dom";
import Approvals from "./approvals";
import NewApproval from "./newApproval";
import ViewApproval from "./viewApproval";

const ApprovalsApp = () => (
  <Switch>
    <Route exact path="/approvals" component={Approvals} />
    <Route exact path="/approvals/new" component={NewApproval} />
    <Route exact path="/approvals/:id" component={ViewApproval} />
  </Switch>
);

export default withRouter(ApprovalsApp);
