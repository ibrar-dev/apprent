import React, {Component} from 'react';
import {Switch, Route, withRouter} from 'react-router-dom';
import Tech from './show';
import Techs from './list';
import Maps from './maps';

class TechsApp extends Component {
  render() {
    return <Switch>
      <Route exact path="/techs" component={Techs}/>
      <Route exact path="/techs/map" component={Maps}/>
      <Route exact path="/techs/:id" component={Tech}/>
    </Switch>
  }
}

export default withRouter(TechsApp);