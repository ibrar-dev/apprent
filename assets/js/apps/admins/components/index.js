import React from "react";
import {Switch, Route, withRouter} from "react-router-dom";
import AdminsApp from "./adminsApp";
import Admin from "./admin";

const Admins = () => (
  <Switch>
    <Route exact path="/admins" component={AdminsApp} />
    <Route exact path="/admins/:id" component={Admin} />
  </Switch>
);

export default withRouter(Admins);
