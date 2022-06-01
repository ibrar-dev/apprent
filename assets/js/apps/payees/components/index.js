import React from 'react';
import {connect} from 'react-redux';
import {Switch, Route, withRouter} from "react-router-dom";
import Payees from './payees';
import Payee from './payeeForm';

class PayeesApp extends React.Component {
  render() {
    const {payees} = this.props;
    return <Switch>
      <Route exact path="/payees/new" render={() => <Payee payee={{}}/>}/>
      <Route exact path="/payees/:id" render={(props) => {
        const id = parseInt(props.match.params.id);
        const payee = payees.find(p => p.id === id);
        return payee ? <Payee payee={payee}/> : <div/>;
      }}/>
      <Route exact path="/payees" component={Payees}/>
    </Switch>
  }
}

export default withRouter(connect(({payees}) => {
  return {payees};
})(PayeesApp));