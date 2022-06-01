import React, {Component} from 'react';
import {Switch, Route, withRouter} from 'react-router-dom';
import Renewals from './renewals/index';
// import ReportsApp from './reports';

class LeasesApp extends Component {
  render() {
    return <Switch>
      {/* <Route exact path="/leases" component={ReportsApp} /> */}
      {/* <Route exact path="/leases/reports" component={ReportsApp} />*/}
      <Route exact path="/leases/renewals" component={Renewals}/>
    </Switch>
  }
}

export default withRouter(LeasesApp)
