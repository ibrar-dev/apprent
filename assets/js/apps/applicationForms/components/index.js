import React from 'react';
import {connect} from 'react-redux';
import {Switch, Route, withRouter} from "react-router-dom";
import Applications from './applications';
import Application from './application';
import Lease from './lease';
import actions from '../actions';

class ApplicationsApp extends React.Component {
  render() {
    const {history, application, units} = this.props;
    return <Switch>
      <Route exact path="/applications/:id/lease" component={Lease}/>
      <Route exact path="/applications/:id" render={(props) => {
        const id = parseInt(props.match.params.id);
        if (application && application.id === id) {
          const propUnits = units.filter(u => u.property_id === application.property.id);
          return <Application history={history} application={application} units={propUnits}/>;
        }
        actions.fetchApplication(id);
        return <div/>;
      }}/>
      <Route exact path="/applications" component={Applications}/>
    </Switch>;
  }
}

export default withRouter(connect(({applications, application, units}) => {
  return {applications, application, units};
})(ApplicationsApp));