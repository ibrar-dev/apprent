import React from "react";
import {Switch, Route, withRouter} from "react-router-dom";
import Orders from "./orders";
import Order from "./show_order";

const OrdersApp = () => (
  <Switch>
    <Route exact path="/orders/:id" render={() => <Order type="workOrder" />} />
    <Route exact path="/vendor_orders/:id" render={() => <Order type="vendor" />} />
    <Route exact path="/orders" render={() => <Orders />} />
  </Switch>
);

export default withRouter(OrdersApp);
