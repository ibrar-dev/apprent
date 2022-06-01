import React from 'react';
import {connect} from 'react-redux';
import {Switch, Route, withRouter} from "react-router-dom";
import Container from './container.js'
import actions from '../actions'
import Reconciliations from './reconciliations'


class ReconciliationApp extends React.Component {

  render() {
    return <>
      <Route exact path="/reconcile" render={() => <Reconciliations/>}/>
      <Route path="/reconcile/:id" render={() => <Container/>}/>
    </>
  }
}

export default withRouter(ReconciliationApp);
