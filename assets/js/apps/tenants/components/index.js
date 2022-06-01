import React from "react";
import {Switch, Route, withRouter} from "react-router-dom";
import Tenants from "./tenants";
import Tenant from "./tenant";
import NewTenant from "./newTenant";
import actions from "../actions";

const TenantsApp = ({history}) => (
  <Switch>
    <Route exact path="/tenants/new" component={NewTenant} />
    <Route
      exact
      path="/tenants/:id"
      render={(props) => {
        const id = parseInt(props.match.params.id);
        setTimeout(() => actions.fetchTenant(props.match.params.id), 1);
        return <Tenant tenantId={id} history={history} />;
      }}
    />
    <Route exact path="/tenants" component={Tenants} />
  </Switch>
);

export default withRouter(TenantsApp);
