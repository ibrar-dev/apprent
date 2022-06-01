import React from 'react';
import {connect} from 'react-redux';
import {Switch, Route, withRouter} from "react-router-dom";
import OrgChart from './orgChart.js'

const initialLineItems = () => [...new Array(5)].map((_, i) => {
  return {id: i + 1, amount_paid: 0, payments: [], validate: i > 0 ? false : true}
});

class PermissionsApp extends React.Component {
  render() {
    return <Switch>
      <Route exact path="/org_chart" render={() => <OrgChart/>}/>
    </Switch>
  }
}

export default withRouter(PermissionsApp);
