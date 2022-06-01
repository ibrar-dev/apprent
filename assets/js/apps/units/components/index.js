import React from "react";
import {Switch, Route, withRouter} from "react-router-dom";
import Units from "./units"
import UnitDetails from "./unitDetails";

class PropertiesApp extends React.Component {
  state = {};

  render() {
    return <Switch>
      <Route exact path="/units/:id" component={UnitDetails}/>
      <Route exact path="/units" component={Units}/>
    </Switch>;
  }
}

export default withRouter(PropertiesApp);
