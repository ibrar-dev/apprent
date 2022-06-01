import React from 'react';
import {connect} from 'react-redux';
import { Switch, Route, withRouter } from 'react-router-dom';
import StockList from './stocks';
import Materials from './materials';
import Report from './report';
import Shop from './shop'

class Stocks extends React.Component {

  render() {
    return <Switch>
      <Route exact path="/materials" component={StockList} />
      <Route exact path="/materials/:id/shop" render={Shop}/>
      <Route exact path="/materials/:id" render={Materials} />
      <Route exact path="/materials/:id/report" component={Report} />
    </Switch>
  }
}

export default withRouter(connect(({stock, report}) => {
  return {stock, report}
})(Stocks));