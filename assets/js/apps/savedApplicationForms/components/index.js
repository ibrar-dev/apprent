import React from 'react';
import {Switch, Route, withRouter} from 'react-router-dom';
import Applications from './applications';

const ApplicationsApp = () => (
  <Switch>
    <Route exact path='/saved_forms' component={Applications}/>
  </Switch>
)

export default withRouter(ApplicationsApp);
